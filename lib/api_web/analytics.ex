defmodule ApiWeb.Analytics do
  @moduledoc """
  Centralizes communication with our analytics tools, please use this to send events
  """
  alias Api.Repo

  @env Application.compile_env!(:api, :env)

  defmodule Provider do
    defmodule Behaviour do
      @moduledoc false
      @callback identify(user_id :: binary, attrs :: map) :: :ok

      @callback track(
                  user_id :: binary | nil,
                  event_name :: binary,
                  attrs :: map
                ) :: :ok
    end

    @behaviour Behaviour

    defmodule Stub do
      @moduledoc false
      @behaviour Behaviour

      def identify(_user_id, _attrs), do: :ok
      def track(_user_id, _event_name, _attrs), do: :ok
    end

    def identify(user_id, attrs) do
      Segment.Analytics.identify(user_id, attrs)
    end

    def track(user_id, event_name, attrs) do
      Segment.Analytics.track(user_id, event_name, attrs)
    end
  end

  def identify(%Api.Accounts.User{} = user) do
    user = user |> Repo.preload([:companies, :members])
    company = user.companies |> Enum.at(0)
    member = user.members |> Enum.at(0)

    company_attr =
      if company != nil do
        %{
          is_paying: company.is_paying,
          # (nadav:) since many services (like Mixpanel) does not support nested values
          # we've decided to add 'company_name' alongside the company object.
          company: %{name: company.name},
          company_name: company.name,
          role:
            case member.role do
              :company_admin -> "Admin"
              :editor -> "Editor"
              :viewer -> "Viewer"
              :presenter -> "Presenter"
            end
        }
      else
        %{
          is_paying: false
        }
      end

    attrs =
      Map.merge(
        %{
          first_name: user.first_name,
          last_name: user.last_name
        },
        company_attr
      )

    if should_send?(user, :identify, attrs),
      do: provider().identify(user.email, attrs),
      else: :ok
  end

  def report_storyline_created(
        %Api.Accounts.User{} = user,
        %Api.Storylines.Storyline{} = storyline,
        attrs \\ %{}
      ) do
    if should_send?(user, :storyline_created, attrs),
      do:
        provider().track(
          user.email,
          "storyline_created",
          attrs |> merge_storyline_attrs(storyline)
        ),
      else: :ok
  end

  def report_storyline_updated(
        %Api.Accounts.User{} = user,
        %Api.Storylines.Storyline{} = storyline,
        attrs \\ %{}
      ) do
    if should_send?(user, :storyline_updated, attrs),
      do:
        provider().track(
          user.email,
          "storyline_updated",
          attrs |> merge_storyline_attrs(storyline)
        ),
      else: :ok
  end

  defp merge_storyline_attrs(attrs, storyline) do
    Map.merge(
      %{
        url: "https://app.teamwalnut.com/storylines/#{storyline.id}"
      },
      attrs
    )
  end

  def report_flow_created(
        %Api.Accounts.User{} = user,
        %Api.Storylines.ScreenGrouping.Flow{} = flow,
        attrs \\ %{}
      ) do
    if should_send?(user, :flow_created, attrs),
      do: provider().track(user.email, "flow_created", attrs |> merge_flow_attrs(flow)),
      else: :ok
  end

  def report_flow_deleted(
        %Api.Accounts.User{} = user,
        %Api.Storylines.ScreenGrouping.Flow{} = flow,
        attrs \\ %{}
      ) do
    if should_send?(user, :flow_deleted, attrs),
      do: provider().track(user.email, "flow_deleted", attrs |> merge_flow_attrs(flow)),
      else: :ok
  end

  def report_flow_renamed(
        %Api.Accounts.User{} = user,
        %Api.Storylines.ScreenGrouping.Flow{} = flow,
        attrs \\ %{}
      ) do
    if should_send?(user, :flow_renamed, attrs),
      do: provider().track(user.email, "flow_renamed", attrs |> merge_flow_attrs(flow)),
      else: :ok
  end

  defp merge_flow_attrs(attrs, flow) do
    Map.merge(
      %{
        storyline: flow.storyline_id,
        flow: flow.id
      },
      attrs
    )
  end

  def report_screen_added(
        %Api.Accounts.User{} = user,
        %Api.Storylines.Screen{} = screen,
        attrs \\ %{}
      ) do
    if should_send?(user, :screen_added, attrs),
      do: provider().track(user.email, "screen_added", attrs |> merge_screen_attrs(screen)),
      else: :ok
  end

  def report_screen_deleted(
        %Api.Accounts.User{} = user,
        %Api.Storylines.Screen{} = screen,
        attrs \\ %{}
      ) do
    if should_send?(user, :screen_deleted, attrs),
      do: provider().track(user.email, "screen_deleted", attrs |> merge_screen_attrs(screen)),
      else: :ok
  end

  def report_screens_deleted(
        %Api.Accounts.User{} = user,
        storyline_id,
        screen_ids,
        attrs \\ %{}
      ) do
    if should_send?(user, :screen_deleted, attrs),
      do:
        provider().track(
          user.email,
          "screens_deleted",
          attrs |> Map.put(:screen_ids, screen_ids) |> Map.put(:storyline_id, storyline_id)
        ),
      else: :ok
  end

  def report_screen_renamed(
        %Api.Accounts.User{} = user,
        %Api.Storylines.Screen{} = screen,
        attrs \\ %{}
      ) do
    if should_send?(user, :screen_renamed, attrs),
      do: provider().track(user.email, "screen_renamed", attrs |> merge_screen_attrs(screen)),
      else: :ok
  end

  defp merge_screen_attrs(attrs, screen) do
    Map.merge(
      %{
        storyline: screen.storyline_id,
        screen: screen.id
      },
      attrs
    )
  end

  def report_edit_created(
        %Api.Accounts.User{} = user,
        %Api.Storylines.Editing.Edit{} = edit,
        attrs \\ %{}
      ) do
    if should_send?(user, :edit_created, attrs),
      do:
        provider().track(user.email, "#{edit.kind}_edit_created", attrs |> merge_edit_attrs(edit)),
      else: :ok
  end

  def report_edit_updated(
        %Api.Accounts.User{} = user,
        %Api.Storylines.Editing.Edit{} = edit,
        attrs \\ %{}
      ) do
    if should_send?(user, :edit_updated, attrs),
      do:
        provider().track(user.email, "#{edit.kind}_edit_updated", attrs |> merge_edit_attrs(edit)),
      else: :ok
  end

  def report_edit_deleted(
        %Api.Accounts.User{} = user,
        %Api.Storylines.Editing.Edit{} = edit,
        attrs \\ %{}
      ) do
    if should_send?(user, :edit_deleted, attrs),
      do:
        provider().track(user.email, "#{edit.kind}_edit_deleted", attrs |> merge_edit_attrs(edit)),
      else: :ok
  end

  defp merge_edit_attrs(attrs, edit) do
    Map.merge(
      %{
        screen: edit.screen_id,
        edit: edit.id
      },
      attrs
    )
  end

  def report_guide_created(
        %Api.Accounts.User{} = user,
        storyline_id,
        %Api.Annotations.Guide{} = guide,
        attrs \\ %{}
      ) do
    attrs = Map.merge(%{storyline: storyline_id}, attrs)

    if should_send?(user, :guide_created, attrs),
      do: provider().track(user.email, "guide_created", attrs |> merge_guide_attrs(guide)),
      else: :ok
  end

  def report_guide_deleted(
        %Api.Accounts.User{} = user,
        %Api.Annotations.Guide{} = guide,
        attrs \\ %{}
      ) do
    if should_send?(user, :guide_deleted, attrs),
      do:
        provider().track(
          user.email,
          "guide_deleted",
          attrs |> merge_guide_attrs(guide)
        ),
      else: :ok
  end

  def report_guide_renamed(
        %Api.Accounts.User{} = user,
        %Api.Annotations.Guide{} = guide,
        attrs \\ %{}
      ) do
    if should_send?(user, :guide_renamed, attrs),
      do:
        provider().track(
          user.email,
          "guide_renamed",
          attrs |> merge_guide_attrs(guide)
        ),
      else: :ok
  end

  defp merge_guide_attrs(attrs, guide) do
    Map.merge(
      %{guide: guide.id},
      attrs
    )
  end

  def report_annotation_added(
        %Api.Accounts.User{} = user,
        guide_id,
        %Api.Annotations.Annotation{} = annotation,
        attrs \\ %{}
      ) do
    if should_send?(user, :annotation_added, attrs),
      do:
        provider().track(
          user.email,
          "annotation_added",
          attrs |> merge_annotation_attrs(guide_id, annotation)
        ),
      else: :ok
  end

  def report_annotation_updated(
        %Api.Accounts.User{} = user,
        guide_id,
        %Api.Annotations.Annotation{} = annotation,
        attrs \\ %{}
      ) do
    if should_send?(user, :annotation_updated, attrs),
      do:
        provider().track(
          user.email,
          "annotation_updated",
          attrs |> merge_annotation_attrs(guide_id, annotation)
        ),
      else: :ok
  end

  def report_annotation_deleted(
        %Api.Accounts.User{} = user,
        guide_id,
        %Api.Annotations.Annotation{} = annotation,
        attrs \\ %{}
      ) do
    if should_send?(user, :annotation_deleted, attrs),
      do:
        provider().track(
          user.email,
          "annotation_deleted",
          attrs |> merge_annotation_attrs(guide_id, annotation)
        ),
      else: :ok
  end

  defp merge_annotation_attrs(attrs, guide_id, annotation) do
    Map.merge(
      %{
        guide: guide_id,
        annotation: annotation.id
      },
      attrs
    )
  end

  def report_demo_created(
        %Api.Accounts.User{} = user,
        %Api.Storylines.Demos.Demo{} = demo,
        attrs \\ %{}
      ) do
    if should_send?(user, :demo_created, attrs),
      do: provider().track(user.email, "demo_created", attrs |> merge_demo_attrs(demo)),
      else: :ok
  end

  def report_demo_updated(
        %Api.Accounts.User{} = user,
        %Api.Storylines.Demos.Demo{} = demo,
        attrs \\ %{}
      ) do
    if should_send?(user, :demo_updated, attrs),
      do: provider().track(user.email, "demo_updated", attrs |> merge_demo_attrs(demo)),
      else: :ok
  end

  def report_demo_renamed(
        %Api.Accounts.User{} = user,
        %Api.Storylines.Demos.Demo{} = demo,
        attrs \\ %{}
      ) do
    if should_send?(user, :demo_renamed, attrs),
      do: provider().track(user.email, "demo_renamed", attrs |> merge_demo_attrs(demo)),
      else: :ok
  end

  def report_demo_played(user, demo, attrs \\ %{})

  def report_demo_played(
        %Api.Accounts.User{} = user,
        %Api.Storylines.Demos.Demo{} = demo,
        attrs
      ) do
    if should_send?(user, :demo_played, attrs),
      do: provider().track(user.email, "demo_played", attrs |> merge_demo_attrs(demo)),
      else: :ok
  end

  def report_demo_played(
        user,
        %Api.Storylines.Demos.Demo{} = demo,
        attrs
      )
      when is_nil(user) do
    if should_send?(user, :demo_played, attrs),
      do: provider().track(nil, "demo_played", attrs |> merge_demo_attrs(demo)),
      else: :ok
  end

  def report_demo_sharing_updated(
        %Api.Accounts.User{} = user,
        %Api.Storylines.Demos.Demo{} = demo,
        attrs \\ %{}
      ) do
    if should_send?(user, :demo_sharing_updated, attrs),
      do: provider().track(user.email, "demo_sharing_updated", attrs |> merge_demo_attrs(demo)),
      else: :ok
  end

  defp merge_demo_attrs(attrs, demo) do
    Map.merge(
      %{
        storyline: demo.storyline_id,
        demo: demo.id
      },
      attrs
    )
  end

  defp provider do
    Application.get_env(:api, :analytics)
  end

  defp should_send?(%Api.Accounts.User{email: email}, _, _attrs) do
    walnut_user = Enum.any?(["@walnut.io", "@teamwalnut.com"], &String.ends_with?(email, &1))
    String.equivalent?(@env, "dev") || !walnut_user
  end

  defp should_send?(nil, :demo_played, _attrs) do
    true
  end

  defp should_send?(nil, _, _attrs) do
    false
  end
end
