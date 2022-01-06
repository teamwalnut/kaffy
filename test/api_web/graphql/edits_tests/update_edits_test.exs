defmodule ApiWeb.GraphQL.UpdateEditsTest do
  use ApiWeb.GraphQLCase
  alias Api.Storylines
  alias Api.TestAccess

  load_gql(
    :add_edits,
    ApiWeb.Schema,
    "test/support/mutations/AddEdits.gql"
  )

  load_gql(
    :update_edits,
    ApiWeb.Schema,
    "test/support/mutations/UpdateEditsInScreen.gql"
  )

  setup [:register_and_log_in_member]

  describe "updateEditsInScreen" do
    test "it should correctly update the edits", %{
      context: %{current_user: %{email: user_email}, current_member: member} = context
    } do
      screen =
        Api.StorylinesFixtures.public_storyline_fixture(member)
        |> Api.StorylinesFixtures.screen_fixture()

      screen2 =
        Api.StorylinesFixtures.public_storyline_fixture(member)
        |> Api.StorylinesFixtures.screen_fixture()

      {:ok, query_data} =
        query_gql_by(
          :add_edits,
          variables: %{"screenId" => screen.id},
          context: context
        )

      no_errors!(query_data)
      edits = get_in(query_data, [:data, "addEditsToScreen"])
      text_edits = edits |> Enum.filter(&(&1["kind"] == "TEXT"))
      style_edit = edits |> Enum.find(&(&1["kind"] == "STYLE"))
      image_edit = edits |> Enum.find(&(&1["kind"] == "CHANGE_IMAGE"))
      link_edit = edits |> Enum.filter(&(&1["kind"] == "LINK")) |> Enum.at(0)
      link_edit_2 = edits |> Enum.filter(&(&1["kind"] == "LINK")) |> Enum.at(1)
      scroll_edit = edits |> Enum.find(&(&1["kind"] == "SCROLL"))
      html_edit = edits |> Enum.find(&(&1["kind"] == "HTML"))
      binding_edit = edits |> Enum.find(&(&1["kind"] == "BINDING"))

      ApiWeb.Analytics.ProviderMock
      |> expect(:track, 9, fn ^user_email, type, _attrs ->
        if type |> String.ends_with?("_edit_updated"), do: :ok, else: :error
      end)

      text_edit1 =
        Enum.at(text_edits, 0)
        |> update_in(["textEditProps", "text"], fn _ -> "updated text" end)
        |> update_in(["textEditProps", "originalText"], fn _ -> "updated original text" end)

      text_edit2 =
        Enum.at(text_edits, 1)
        |> update_in(["textEditProps", "text"], fn _ -> "updated text" end)
        |> update_in(["textEditProps", "originalText"], fn _ -> "updated original text" end)

      style_edit = style_edit |> update_in(["styleEditProps", "color"], fn _ -> "copy copy" end)

      html_edit =
        html_edit
        |> update_in(["htmlEditProps", "value"], fn _ -> "updated dom element" end)
        |> update_in(["htmlEditProps", "originalValue"], fn _ -> "original dom element" end)

      image_edit =
        image_edit
        |> update_in(["changeImageEditProps", "imageUrl"], fn _ -> "updated_image_url" end)
        |> update_in(["changeImageEditProps", "originalImageUrl"], fn _ ->
          "updated original image url"
        end)

      link_edit =
        link_edit
        |> update_in(["linkEditProps"], fn _ -> %{"toScreen" => %{"id" => screen2.id}} end)

      link_edit_2 =
        link_edit_2
        |> update_in(["linkEditProps"], fn _ -> %{"toScreen" => %{"id" => screen2.id}} end)

      scroll_edit =
        scroll_edit
        |> update_in(["scrollEditProps"], fn _ -> %{"top" => 200.0, "left" => 2.0} end)

      binding_edit_updated_program =
        "{\"@astVersion\":\"Ast_20210525\",\"@envVersion\":\"Env_20210525\",\"@expression\":{\"@args\":[{\"@name\":\"name\",\"@value\":\"name test\"},{\"@name\":\"defaultValue\",\"@value\":\"updated default value\"},{\"@name\":\"description\",\"@value\":\"updated desc\"}],\"@fnName\":\"PUBLIC_FIELD\",\"@id\":\"ef44f562-1d5e-4d38-bf59-7ef7a402380d\",\"@type\":\"Call\"}}"

      binding_edit =
        binding_edit
        |> update_in(["bindingEditProps", "program"], fn _ ->
          binding_edit_updated_program
        end)
        |> update_in(["bindingEditProps", "originalText"], fn _ -> "original dom element" end)

      screen = screen |> Api.Repo.preload(:flow)
      storyline = Storylines.get_storyline!(screen.flow.storyline_id)
      last_edited_before_updating_edits = storyline.last_edited

      {:ok, query_data} =
        query_gql_by(
          :update_edits,
          variables: %{
            "screenId" => screen.id,
            "edits" => [
              text_edit1,
              text_edit2,
              style_edit,
              image_edit,
              link_edit,
              link_edit_2,
              scroll_edit,
              html_edit,
              binding_edit
            ]
          },
          context: context
        )

      no_errors!(query_data)
      results = get_in(query_data, [:data, "updateEditsInScreen"])

      assert results == [
               %{
                 "domSelector" => %{"xpathFrames" => [], "xpathNode" => "div"},
                 "frameSelectors" => nil,
                 "cssSelector" => ".text",
                 "id" => results |> Enum.at(0) |> Map.get("id"),
                 "kind" => "TEXT",
                 "lastEditedAt" => "2021-02-21T15:44:56.868000Z",
                 "textEditProps" => %{
                   "originalText" => "updated original text",
                   "text" => "updated text"
                 }
               },
               %{
                 "domSelector" => %{"xpathFrames" => [], "xpathNode" => "div"},
                 "frameSelectors" => ["iframe"],
                 "cssSelector" => ".text",
                 "id" => results |> Enum.at(1) |> Map.get("id"),
                 "kind" => "TEXT",
                 "lastEditedAt" => "2021-02-21T15:44:56.868000Z",
                 "textEditProps" => %{
                   "originalText" => "updated original text",
                   "text" => "updated text"
                 }
               },
               %{
                 "domSelector" => %{"xpathFrames" => [], "xpathNode" => "div"},
                 "frameSelectors" => ["iframe"],
                 "cssSelector" => ".style",
                 "id" => results |> Enum.at(2) |> Map.get("id"),
                 "kind" => "STYLE",
                 "lastEditedAt" => "2021-02-21T15:44:56.868000Z",
                 "styleEditProps" => %{
                   "bold" => true,
                   "hide" => true,
                   "color" => "copy copy",
                   "font_size" => "10px",
                   "underline" => true
                 }
               },
               %{
                 "changeImageEditProps" => %{
                   "originalImageUrl" => "updated original image url",
                   "imageUrl" => "updated_image_url"
                 },
                 "domSelector" => %{"xpathFrames" => [], "xpathNode" => "div"},
                 "frameSelectors" => ["iframe"],
                 "cssSelector" => ".image",
                 "id" => results |> Enum.at(3) |> Map.get("id"),
                 "kind" => "CHANGE_IMAGE",
                 "lastEditedAt" => "2021-02-21T15:44:56.868000Z"
               },
               %{
                 "domSelector" => %{"xpathFrames" => [], "xpathNode" => "div"},
                 "frameSelectors" => ["iframe"],
                 "cssSelector" => ".link",
                 "id" => results |> Enum.at(4) |> Map.get("id"),
                 "kind" => "LINK",
                 "lastEditedAt" => "2021-02-21T15:44:56.868000Z",
                 "linkEditProps" => %{
                   "destination" => %{"screen" => %{"id" => screen2.id}}
                 }
               },
               %{
                 "domSelector" => %{"xpathFrames" => [], "xpathNode" => "div"},
                 "frameSelectors" => ["iframe"],
                 "cssSelector" => ".link",
                 "id" => results |> Enum.at(5) |> Map.get("id"),
                 "kind" => "LINK",
                 "lastEditedAt" => "2021-02-21T15:44:56.868000Z",
                 "linkEditProps" => %{
                   "destination" => %{"screen" => %{"id" => screen2.id}}
                 }
               },
               %{
                 "domSelector" => %{"xpathFrames" => [], "xpathNode" => "div"},
                 "frameSelectors" => ["iframe"],
                 "cssSelector" => ".scroll",
                 "id" => results |> Enum.at(6) |> Map.get("id"),
                 "kind" => "SCROLL",
                 "lastEditedAt" => "2021-02-21T15:44:56.868000Z",
                 "scrollEditProps" => %{
                   "top" => 200.0,
                   "left" => 2.0
                 }
               },
               %{
                 "domSelector" => %{"xpathFrames" => [], "xpathNode" => "div"},
                 "frameSelectors" => ["iframe"],
                 "cssSelector" => ".html",
                 "id" => results |> Enum.at(7) |> Map.get("id"),
                 "kind" => "HTML",
                 "lastEditedAt" => "2021-02-21T15:44:56.868000Z",
                 "htmlEditProps" => %{
                   "value" => "updated dom element",
                   "originalValue" => "original dom element"
                 }
               },
               %{
                 "domSelector" => %{"xpathFrames" => [], "xpathNode" => "div"},
                 "frameSelectors" => ["iframe"],
                 "cssSelector" => ".bind",
                 "id" => results |> Enum.at(8) |> Map.get("id"),
                 "kind" => "BINDING",
                 "lastEditedAt" => "2021-02-21T15:44:56.868000Z",
                 "bindingEditProps" => %{
                   "program" => binding_edit_updated_program,
                   "originalText" => "original dom element"
                 }
               }
             ]

      storyline = Storylines.get_storyline!(screen.flow.storyline_id)
      assert DateTime.compare(storyline.last_edited, last_edited_before_updating_edits) == :gt
    end

    test "authorize", %{context: %{current_member: member} = context} do
      screen =
        Api.StorylinesFixtures.public_storyline_fixture(member)
        |> Api.StorylinesFixtures.screen_fixture()

      {:ok, query_data} =
        query_gql_by(
          :add_edits,
          variables: %{"screenId" => screen.id},
          context: context
        )

      no_errors!(query_data)
      edits = get_in(query_data, [:data, "addEditsToScreen"])
      text_edits = edits |> Enum.filter(&(&1["kind"] == "TEXT"))

      text_edit1 =
        Enum.at(text_edits, 0)
        |> update_in(["textEditProps", "text"], fn _ -> "updated text" end)
        |> update_in(["textEditProps", "originalText"], fn _ -> "updated original text" end)

      text_edit2 =
        Enum.at(text_edits, 1)
        |> update_in(["textEditProps", "text"], fn _ -> "updated text" end)
        |> update_in(["textEditProps", "originalText"], fn _ -> "updated original text" end)

      TestAccess.assert_roles(
        &query_gql_by(
          :update_edits,
          variables: %{"screenId" => screen.id, "edits" => [text_edit1, text_edit2]},
          context: Map.put(context, :current_member, &1)
        ),
        context.current_member,
        %TestAccess{viewer: false, presenter: true, editor: true, company_admin: true}
      )
    end
  end
end
