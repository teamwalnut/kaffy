defmodule ApiWeb.Schema.CompanyTypes do
  @moduledoc false
  use Absinthe.Schema.Notation
  import Absinthe.Resolution.Helpers
  alias ApiWeb.FeaturesFlags.Provider.Launchdarkly
  alias ApiWeb.Middlewares

  @desc "Custom Domain"
  object :custom_domain do
    field(:domain, :string)
  end

  @desc "Companies"
  object :company do
    field(:id, non_null(:id))
    field(:last_updated, :datetime)
    field(:name, non_null(:string))
    field(:members, non_null(list_of(non_null(:member))), resolve: dataloader(:member))

    field(:member_invites, non_null(list_of(non_null(:member_invite))),
      resolve: dataloader(:member_invite)
    )

    field(:patches, list_of(non_null(:patch)), resolve: dataloader(:patch))
    field(:custom_domain, :custom_domain, resolve: dataloader(:custom_domain))
  end

  enum :role do
    values(Ecto.Enum.values(Api.Companies.Member, :role))
  end

  @desc "A member of a company, its a type that connects between a user and a company"
  object :member do
    field(:id, non_null(:id))
    field(:company, non_null(:company), resolve: dataloader(:company))
    field(:company_id, non_null(:id))
    field(:role, :role)
    field(:user, non_null(:user), resolve: dataloader(:user))
  end

  @desc "A member invitation to a company"
  object :member_invite do
    field(:id, non_null(:id))
    field(:company, non_null(:company), resolve: dataloader(:company))
    field(:member, :member, resolve: dataloader(:member))
    field(:email, non_null(:string))
    field(:role, non_null(:role))
    field(:expires_at, non_null(:datetime))
  end

  object :bulk_invitation_result do
    field(:invites_sent, list_of(non_null(:member_invite)))
    field(:invites_failed, list_of(non_null(:string)))
  end

  object :company_queries do
    field :current_company, non_null(:company) do
      middleware(Middlewares.AuthnRequired)

      resolve(fn _parent, _args, %{context: %{current_user: current_user}} ->
        get_member_and_company_by_user_id(current_user.id)
      end)
    end

    field :company, :company do
      middleware(Middlewares.AuthnRequired)
      arg(:id, non_null(:id))

      resolve(fn _parent, %{id: id}, _context ->
        {:ok, Api.Companies.get_company!(id)}
      end)
    end
  end

  object :company_mutations do
    @desc "Invites many emails to a company"
    field :bulk_invite_members, non_null(:bulk_invitation_result) do
      middleware(Middlewares.AuthnRequired)
      arg(:emails, non_null(list_of(non_null(:string))))
      arg(:company_id, non_null(:id))
      arg(:role, :role)

      resolve(fn _parent,
                 %{emails: emails, company_id: company_id} = attrs,
                 %{context: %{current_member: _current_member}} ->
        case Api.Companies.get_company(company_id) do
          {:ok, company} ->
            results =
              emails
              |> Enum.map(&invite_one_email(&1, company, attrs[:role]))
              |> Enum.reduce(
                %{invites_sent: [], invites_failed: []},
                fn
                  {:ok, invite}, acc -> %{acc | invites_sent: [invite | acc.invites_sent]}
                  {:error, error}, acc -> %{acc | invites_failed: [error | acc.invites_failed]}
                end
              )

            {:ok, results}

          {:error, _} ->
            {:error, :invalid_company_id}
        end
      end)
    end

    @desc "Invites a member to a company"
    field :invite_member, non_null(:member_invite) do
      middleware(Middlewares.AuthnRequired)
      arg(:email, non_null(:string))
      arg(:role, :role)

      resolve(fn _parent,
                 %{email: email} = attrs,
                 %{context: %{current_member: current_member}} ->
        case Api.MemberInvite.invite_member(email, current_member, attrs[:role] || :company_admin) do
          {:ok, %{member_invite: member_invite, encoded_token: token}} ->
            ApiWeb.Emails.Companies.invite_member(
              current_member.company,
              member_invite.email,
              token
            )
            |> Api.Mailer.deliver_later!()

            {:ok, member_invite}

          err ->
            err
        end
      end)
    end

    @desc "Accepts a member invitation to a company"
    field :accept_member_invitation, non_null(:member) do
      # We are not requiring auth here since the process of accepting an invite expects you to be logged out
      arg(:token, non_null(:string))
      arg(:user_attributes, non_null(:user_accept_invite_props))

      resolve(fn _parent, %{token: token, user_attributes: user_attributes}, _context ->
        case Api.MemberInvite.accept_member_invitation(token, user_attributes) do
          {:ok, %{member: member}} ->
            member = member |> Api.Repo.preload(:user)
            :ok = member.user |> Launchdarkly.identify()

            {:ok, member}

          err ->
            err
        end
      end)
    end

    @desc "Delete a member invitation to a company"
    field :delete_member_invitation, non_null(:member_invite) do
      middleware(Middlewares.AuthnRequired)
      arg(:member_invite_id, non_null(:id))

      resolve(fn _parent,
                 %{member_invite_id: member_invite_id},
                 %{context: %{current_member: actor}} ->
        member_invite = Api.MemberInvite.get_member_invite!(member_invite_id)

        case Api.MemberInvite.delete_member_invite(member_invite, actor) do
          {:ok, %Api.Companies.MemberInvite{} = member_invite} ->
            {:ok, member_invite}

          err ->
            err
        end
      end)
    end

    @desc "Deletes a member from a company"
    field :delete_member, non_null(:member) do
      middleware(Middlewares.AuthnRequired)
      arg(:member_id, non_null(:id))

      resolve(fn _parent, %{member_id: member_id}, %{context: %{current_member: actor}} ->
        with member_to_delete <- Api.Companies.get_member!(member_id) do
          Api.Companies.delete_member(member_to_delete, actor)
        end
      end)
    end

    @desc "Update Member Role"
    field :update_member_role, non_null(:member) do
      middleware(Middlewares.AuthnRequired)
      arg(:member_id, non_null(:id))
      arg(:role, non_null(:role))

      resolve(fn _parent,
                 %{member_id: member_id, role: role},
                 %{context: %{current_user: _current_user}} ->
        member = Api.Companies.get_member!(member_id)

        case Api.Companies.update_member_role(member, role) do
          {:ok, %Api.Companies.Member{} = updated_member} ->
            {:ok, updated_member}

          err ->
            err
        end
      end)
    end
  end

  defp invite_one_email(email, company, role) do
    with {:ok, %{member_invite: member_invite, encoded_token: token}} <-
           Api.MemberInvite.invite_member_for_company(email, company.id, role || :company_admin) do
      ApiWeb.Emails.Companies.invite_member(company, member_invite.email, token)
      |> Api.Mailer.deliver_later!()

      {:ok, member_invite}
    end
  end

  defp get_member_and_company_by_user_id(user_id) do
    member = Api.Companies.member_from_user(user_id) |> Api.Repo.preload(:company)

    case member.company do
      %Api.Companies.Company{} = company -> {:ok, company}
      _ -> {:error, :member_does_not_belong_to_a_company}
    end
  end
end
