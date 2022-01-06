defmodule ApiWeb.GraphQL.AddModalAnnotationToGuide do
  use ApiWeb.GraphQLCase

  alias Api.Annotations
  alias Api.Annotations.Annotation
  alias Api.TestAccess

  load_gql(
    :add_modal_annotation_to_guide,
    ApiWeb.Schema,
    "test/support/mutations/annotations/AddModalAnnotationToGuide.gql"
  )

  setup [
    :register_and_log_in_member,
    :setup_public_storyline,
    :setup_screen,
    :setup_guide
  ]

  describe "AddModalAnnotationToGuide" do
    test "it adds a modal annotation to a given guide", %{
      context: %{current_user: %{email: user_email}} = context,
      screen: screen,
      guide: %{id: guide_id}
    } do
      ApiWeb.Analytics.ProviderMock
      |> expect(:track, fn ^user_email,
                           "annotation_added",
                           %{guide: ^guide_id, annotation: _annotation_id} ->
        :ok
      end)

      assert {:ok, query_data} =
               query_gql_by(
                 :add_modal_annotation_to_guide,
                 variables: %{
                   "guideId" => guide_id,
                   "screenId" => screen.id,
                   "message" => "message",
                   "hasOverlay" => false,
                   "richTextAsJson" =>
                     Jason.encode!(%{
                       "delta" => %{"ops" => [%{"insert" => "some message"}, %{"insert" => "\n"}]},
                       "version" => "QuillDelta_20211027"
                     }),
                   "settings" => %{
                     "showMainButton" => false,
                     "mainButtonText" => "n3xT",
                     "showDismissButton" => false,
                     "showBackButton" => false,
                     "showAvatar" => true,
                     "avatarUrl" => "https://www.walnut.io",
                     "avatarTitle" => "Paz from Walnut",
                     "showDim" => true,
                     "size" => "SMALL"
                   }
                 },
                 context: context
               )

      no_errors!(query_data)

      result = get_in(query_data, [:data, "addModalAnnotationToGuide"])

      assert result["id"] != nil
      assert result["settings"]["showMainButton"] == false
      assert result["settings"]["mainButtonText"] == "n3xT"
      assert result["settings"]["showDismissButton"] == false
      assert result["settings"]["showBackButton"] == false
      assert result["settings"]["showAvatar"] == true
      assert result["settings"]["avatarUrl"] == "https://www.walnut.io"
      assert result["settings"]["avatarTitle"] == "Paz from Walnut"
      assert result["settings"]["showDim"] == true
      assert result["settings"]["size"] == "SMALL"
    end

    test "it adds a modal annotation in the passed step to a given guide", %{
      context: %{current_user: %{email: user_email}} = context,
      screen: screen,
      guide: %{id: guide_id},
      member: member
    } do
      ApiWeb.Analytics.ProviderMock
      |> expect(:track, fn ^user_email,
                           "annotation_added",
                           %{guide: ^guide_id, annotation: _annotation_id} ->
        :ok
      end)

      modal_attrs = %{
        kind: :modal,
        message: "some message",
        hasOverlay: true,
        rich_text: %{
          "delta" => %{"ops" => [%{"insert" => "some message"}, %{"insert" => "\n"}]},
          "version" => "QuillDelta_20211027"
        },
        last_edited: "2010-04-17T14:00:00Z",
        screen_id: screen.id
      }

      {:ok, %Annotation{} = _modal0} =
        Annotations.add_annotation_to_guide(guide_id, modal_attrs, :modal, member)

      {:ok, %Annotation{} = modal1} =
        Annotations.add_annotation_to_guide(guide_id, modal_attrs, :modal, member)

      assert {:ok, query_data} =
               query_gql_by(
                 :add_modal_annotation_to_guide,
                 variables: %{
                   "guideId" => guide_id,
                   "screenId" => screen.id,
                   "message" => "message",
                   "hasOverlay" => true,
                   "richTextAsJson" =>
                     Jason.encode!(%{
                       "delta" => %{"ops" => [%{"insert" => "some message"}, %{"insert" => "\n"}]},
                       "version" => "QuillDelta_20211027"
                     }),
                   "step" => modal1.step,
                   "settings" => %{
                     "showMainButton" => false,
                     "mainButtonText" => "n3xT",
                     "showDismissButton" => false,
                     "showBackButton" => false,
                     "showAvatar" => true,
                     "avatarUrl" => "https://www.walnut.io",
                     "avatarTitle" => "Paz from Walnut",
                     "showDim" => true,
                     "size" => "SMALL"
                   }
                 },
                 context: context
               )

      no_errors!(query_data)

      result = get_in(query_data, [:data, "addModalAnnotationToGuide"])

      assert result["id"] != nil
      assert result["settings"]["showMainButton"] == false
      assert result["settings"]["mainButtonText"] == "n3xT"
      assert result["settings"]["showDismissButton"] == false
      assert result["settings"]["showBackButton"] == false
      assert result["settings"]["showAvatar"] == true
      assert result["settings"]["avatarUrl"] == "https://www.walnut.io"
      assert result["settings"]["avatarTitle"] == "Paz from Walnut"
      assert result["settings"]["showDim"] == true
      assert result["settings"]["size"] == "SMALL"
    end

    test "it doesn't adds a modal annotation when message is empty", %{
      context: context,
      screen: screen,
      guide: %{id: guide_id}
    } do
      assert {:ok, query_data} =
               query_gql_by(
                 :add_modal_annotation_to_guide,
                 variables: %{
                   "guideId" => guide_id,
                   "screenId" => screen.id,
                   "message" => "",
                   "hasOverlay" => false,
                   "richTextAsJson" => ""
                 },
                 context: context
               )

      errors = get_in(query_data, [:errors])
      assert errors != nil

      error = List.first(errors)

      assert error[:message] ==
               "Rich_text one of these fields must be present: [:rich_text, :message]"
    end

    test "authorization", %{context: context, screen: screen, guide: %{id: guide_id}} do
      TestAccess.assert_roles(
        &query_gql_by(
          :add_modal_annotation_to_guide,
          variables: %{
            "guideId" => guide_id,
            "screenId" => screen.id,
            "hasOverlay" => false,
            "message" => "message",
            "richTextAsJson" => ""
          },
          context: Map.put(context, :current_member, &1)
        ),
        context.current_member,
        %TestAccess{viewer: false, presenter: true, editor: true, company_admin: true}
      )
    end
  end
end
