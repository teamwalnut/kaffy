defmodule ApiWeb.GraphQL.AddPointAnnotationToGuide do
  use ApiWeb.GraphQLCase

  alias Api.Annotations
  alias Api.Annotations.Annotation
  alias Api.TestAccess

  load_gql(
    :add_point_annotation_to_guide,
    ApiWeb.Schema,
    "test/support/mutations/annotations/AddPointAnnotationToGuide.gql"
  )

  setup [
    :register_and_log_in_member,
    :setup_public_storyline,
    :setup_screen,
    :setup_guide
  ]

  describe "AddPointAnnotationToGuide" do
    test "it adds a point annotation to a given guide", %{
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
                 :add_point_annotation_to_guide,
                 variables: %{
                   "guideId" => guide_id,
                   "screenId" => screen.id,
                   "message" => "message",
                   "richTextAsJson" =>
                     Jason.encode!(%{
                       "delta" => %{"ops" => [%{"insert" => "some message"}, %{"insert" => "\n"}]},
                       "version" => "QuillDelta_20211027"
                     }),
                   "cssSelector" => "css.selctor",
                   "frameSelectors" => [],
                   "anchor" => "TOP",
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

      result = get_in(query_data, [:data, "addPointAnnotationToGuide"])

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

    test "it adds a point annotation in the passed step to a given guide", %{
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

      point_attrs = %{
        kind: :point,
        message: "some message",
        rich_text: %{
          "delta" => %{"ops" => [%{"insert" => "some message"}, %{"insert" => "\n"}]},
          "version" => "QuillDelta_20211027"
        },
        last_edited: "2010-04-17T14:00:00Z",
        frame_selectors: ["iframe"],
        css_selector: "some css selector",
        anchor: :top,
        screen_id: screen.id
      }

      {:ok, %Annotation{} = _point0} =
        Annotations.add_annotation_to_guide(guide_id, point_attrs, :point, member)

      {:ok, %Annotation{} = point1} =
        Annotations.add_annotation_to_guide(guide_id, point_attrs, :point, member)

      assert {:ok, query_data} =
               query_gql_by(
                 :add_point_annotation_to_guide,
                 variables: %{
                   "guideId" => guide_id,
                   "screenId" => screen.id,
                   "message" => "message",
                   "richTextAsJson" =>
                     Jason.encode!(%{
                       "delta" => %{"ops" => [%{"insert" => "some message"}, %{"insert" => "\n"}]},
                       "version" => "QuillDelta_20211027"
                     }),
                   "cssSelector" => "css.selctor",
                   "frameSelectors" => [],
                   "anchor" => "TOP",
                   "step" => point1.step,
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

      result = get_in(query_data, [:data, "addPointAnnotationToGuide"])

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

    test "it doesn't adds a point annotation when some fields are empty", %{
      context: context,
      screen: screen,
      guide: %{id: guide_id}
    } do
      assert {:ok, query_data} =
               query_gql_by(
                 :add_point_annotation_to_guide,
                 variables: %{
                   "guideId" => guide_id,
                   "screenId" => screen.id,
                   "message" => "",
                   "richTextAsJson" => "",
                   "cssSelector" => "",
                   "frameSelectors" => nil,
                   "anchor" => "TOP",
                   "hasOverlay" => false
                 },
                 context: context
               )

      errors = get_in(query_data, [:errors])
      assert errors != nil

      error = List.first(errors)
      assert error[:message] =~ "can't be blank"
    end

    test "authorization", %{context: context, screen: screen, guide: %{id: guide_id}} do
      TestAccess.assert_roles(
        &query_gql_by(
          :add_point_annotation_to_guide,
          variables: %{
            "guideId" => guide_id,
            "screenId" => screen.id,
            "message" => "message",
            "cssSelector" => "css.selctor",
            "richTextAsJson" => "",
            "frameSelectors" => [],
            "anchor" => "TOP"
          },
          context: Map.put(context, :current_member, &1)
        ),
        context.current_member,
        %TestAccess{viewer: false, presenter: true, editor: true, company_admin: true}
      )
    end
  end
end
