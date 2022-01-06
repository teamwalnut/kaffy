alias Api.Storylines.Storyline
alias Api.Accounts.User
alias Api.Companies.Member

defimpl AccessPolicy, for: Storyline do
  def preloads(_storyline), do: [owner: [], collaborators: []]

  @spec authorize(Storyline.t(), Member.t(), :creator | :editor | :viewer | :superadmin) ::
          {:error, :unauthorized} | :ok
  def authorize(resource, actor, expected_relationship)

  # authorize "super admins" to do everything, this is the only rule that also captures the
  # superadmin relationship
  def authorize(_, %Member{user: %User{is_admin: true}}, _), do: :ok

  # never authorize an actor outside of the organization that the storyline is part of
  def authorize(
        %Storyline{owner: %{company_id: owner_company_id}},
        %Member{company_id: actor_company_id},
        _
      )
      when owner_company_id != actor_company_id,
      do: {:error, :unauthorized}

  def authorize(_, %Member{role: role}, :creator) when role in [:company_admin, :editor], do: :ok

  def authorize(%Storyline{is_public: true}, %Member{role: role}, :editor)
      when role in [:company_admin, :editor],
      do: :ok

  def authorize(%Storyline{is_public: true}, %Member{role: role}, :presenter)
      when role in [:company_admin, :editor, :presenter],
      do: :ok

  def authorize(%Storyline{is_public: true}, %Member{role: role}, :viewer)
      when role in [:company_admin, :editor, :presenter, :viewer],
      do: :ok

  def authorize(
        %Storyline{is_public: false, owner: owner, collaborators: collaborators},
        %Member{role: role, id: member_id},
        :editor
      )
      when role in [:company_admin, :editor] do
    case owner.id == member_id || Enum.any?(collaborators, &(&1.member_id == member_id)) do
      true -> :ok
      false -> {:error, :unauthorized}
    end
  end

  def authorize(
        %Storyline{is_public: false, owner: owner, collaborators: collaborators},
        %Member{role: role, id: member_id},
        :presenter
      )
      when role in [:company_admin, :editor, :presenter] do
    case owner.id == member_id || Enum.any?(collaborators, &(&1.member_id == member_id)) do
      true -> :ok
      false -> {:error, :unauthorized}
    end
  end

  def authorize(
        %Storyline{owner: owner, is_public: false, collaborators: collaborators},
        %Member{role: role, id: member_id},
        :viewer
      )
      when role in [:company_admin, :editor, :presenter, :viewer] do
    case owner.id == member_id || Enum.any?(collaborators, &(&1.member_id == member_id)) do
      true -> :ok
      false -> {:error, :unauthorized}
    end
  end

  def authorize(_, _, _), do: {:error, :unauthorized}
end
