defmodule ApiWeb.GraphQL.UpdateAnnotation do
  use ApiWeb.GraphQLCase
  alias Api.TestAccess

  load_gql(
    :update_annotation,
    ApiWeb.Schema,
    "test/support/mutations/annotations/UpdateAnnotation.gql"
  )

  setup [
    :register_and_log_in_member,
    :setup_public_storyline,
    :setup_screen,
    :setup_guide,
    :setup_modal_annotation
  ]

  describe "UpdateAnnotation" do
    test "it updates an annotation and then reupdates", %{
      context: %{current_user: %{email: user_email}} = context,
      screen: screen,
      annotation: %{id: annotation_id},
      guide: %{id: guide_id}
    } do
      ApiWeb.Analytics.ProviderMock
      |> expect(:track, 2, fn ^user_email,
                              "annotation_updated",
                              %{guide: ^guide_id, annotation: ^annotation_id} ->
        :ok
      end)

      assert {:ok, query_data} =
               query_gql_by(
                 :update_annotation,
                 variables: %{
                   "id" => annotation_id,
                   "kind" => "POINT",
                   "screenId" => screen.id,
                   "message" => "new message",
                   "richTextAsJson" =>
                     Jason.encode!(%{
                       "delta" => %{"ops" => [%{"insert" => "some message"}, %{"insert" => "\n"}]},
                       "version" => "QuillDelta_20211027"
                     }),
                   "cssSelector" => "new.css.selctor",
                   "frameSelectors" => ["new"],
                   "anchor" => "BOTTOM",
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

      result = get_in(query_data, [:data, "updateAnnotation"])

      assert result["id"] != nil
      assert result["kind"] == "POINT"
      assert result["anchor"] == "BOTTOM"
      assert result["settings"]["showMainButton"] == false
      assert result["settings"]["mainButtonText"] == "n3xT"
      assert result["settings"]["showDismissButton"] == false
      assert result["settings"]["showBackButton"] == false
      assert result["settings"]["showAvatar"] == true
      assert result["settings"]["avatarUrl"] == "https://www.walnut.io"
      assert result["settings"]["avatarTitle"] == "Paz from Walnut"
      assert result["settings"]["showDim"] == true
      assert result["settings"]["size"] == "SMALL"

      assert {:ok, query_data} =
               query_gql_by(
                 :update_annotation,
                 variables: %{
                   "id" => annotation_id,
                   "kind" => "MODAL",
                   "screenId" => screen.id,
                   "message" => "newer message",
                   "richTextAsJson" =>
                     Jason.encode!(%{
                       "delta" => %{
                         "ops" => [%{"insert" => "newer message"}, %{"insert" => "\n"}]
                       },
                       "version" => "QuillDelta_20211027"
                     }),
                   "cssSelector" => "newer.css.selctor",
                   "frameSelectors" => ["newer"],
                   "anchor" => "TOP",
                   "hasOverlay" => true,
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

      result = get_in(query_data, [:data, "updateAnnotation"])

      assert result["id"] != nil
      assert result["kind"] == "MODAL"
      assert is_nil(result["anchor"])
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

    test "it updates an annotation with empty message", %{
      context: %{current_user: %{email: user_email}} = context,
      screen: screen,
      annotation: %{id: annotation_id},
      guide: %{id: guide_id}
    } do
      ApiWeb.Analytics.ProviderMock
      |> expect(:track, 1, fn ^user_email,
                              "annotation_updated",
                              %{guide: ^guide_id, annotation: ^annotation_id} ->
        :ok
      end)

      assert {:ok, query_data} =
               query_gql_by(
                 :update_annotation,
                 variables: %{
                   "id" => annotation_id,
                   "kind" => "POINT",
                   "screenId" => screen.id,
                   "message" => "",
                   "richTextAsJson" =>
                     Jason.encode!(%{
                       "delta" => %{"ops" => [%{"insert" => "some message"}, %{"insert" => "\n"}]},
                       "version" => "QuillDelta_20211027"
                     }),
                   "cssSelector" => "new.css.selctor",
                   "frameSelectors" => ["new"],
                   "anchor" => "BOTTOM",
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

      result = get_in(query_data, [:data, "updateAnnotation"])

      assert result["id"] != nil
      assert result["kind"] == "POINT"
      assert result["message"] == ""
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

    test "authorization", %{context: context, screen: screen, annotation: %{id: annotation_id}} do
      TestAccess.assert_roles(
        &query_gql_by(
          :update_annotation,
          variables: %{
            "id" => annotation_id,
            "kind" => "POINT",
            "screenId" => screen.id,
            "message" => "new message",
            "cssSelector" => "new.css.selctor",
            "frameSelectors" => ["new"],
            "anchor" => "BOTTOM",
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
