defmodule ApiWeb.GraphQL.AddEditsTest do
  use ApiWeb.GraphQLCase
  alias Api.Storylines
  alias Api.TestAccess

  load_gql(
    :add_edits,
    ApiWeb.Schema,
    "test/support/mutations/AddEdits.gql"
  )

  load_gql(
    :add_edits_dynamic,
    ApiWeb.Schema,
    "test/support/mutations/AddEditsDynamic.gql"
  )

  setup [:verify_on_exit!, :register_and_log_in_member]

  describe "addEditsToScreen" do
    test "it should append edits correctly depending on their type", %{
      context: %{current_user: %{email: user_email}, current_member: member} = context
    } do
      ApiWeb.Analytics.ProviderMock
      |> expect(:track, 9, fn ^user_email, type, _attrs ->
        if type |> String.ends_with?("edit_created"), do: :ok, else: :error
      end)

      screen =
        Api.StorylinesFixtures.public_storyline_fixture(member)
        |> Api.StorylinesFixtures.screen_fixture()

      screen = screen |> Api.Repo.preload(:flow)
      storyline = Storylines.get_storyline!(screen.flow.storyline_id)
      last_edited_before_adding_edits = storyline.last_edited

      result = query_gql_by(:add_edits, variables: %{"screenId" => screen.id}, context: context)

      assert {:ok, query_data} = result
      no_errors!(query_data)

      results = get_in(query_data, [:data, "addEditsToScreen"])

      assert results == [
               %{
                 "domSelector" => %{
                   "xpathNode" => "div",
                   "xpathFrames" => []
                 },
                 "frameSelectors" => nil,
                 "cssSelector" => ".text",
                 "id" => results |> Enum.at(0) |> Map.get("id"),
                 "kind" => "TEXT",
                 "lastEditedAt" => "2021-02-21T15:44:56.868000Z",
                 "textEditProps" => %{"originalText" => "original text", "text" => "new text"}
               },
               %{
                 "domSelector" => %{
                   "xpathNode" => "div",
                   "xpathFrames" => []
                 },
                 "frameSelectors" => ["iframe"],
                 "cssSelector" => ".text",
                 "id" => results |> Enum.at(1) |> Map.get("id"),
                 "kind" => "TEXT",
                 "lastEditedAt" => "2021-02-21T15:44:56.868000Z",
                 "textEditProps" => %{"originalText" => "original text", "text" => "new text"}
               },
               %{
                 "domSelector" => %{
                   "xpathNode" => "div",
                   "xpathFrames" => []
                 },
                 "frameSelectors" => ["iframe"],
                 "cssSelector" => ".style",
                 "id" => results |> Enum.at(2) |> Map.get("id"),
                 "kind" => "STYLE",
                 "lastEditedAt" => "2021-02-21T15:44:56.868000Z",
                 "styleEditProps" => %{
                   "bold" => true,
                   "hide" => true,
                   "color" => "#ssss",
                   "font_size" => "10px",
                   "underline" => true
                 }
               },
               %{
                 "domSelector" => %{
                   "xpathNode" => "div",
                   "xpathFrames" => []
                 },
                 "frameSelectors" => ["iframe"],
                 "cssSelector" => ".image",
                 "id" => results |> Enum.at(3) |> Map.get("id"),
                 "kind" => "CHANGE_IMAGE",
                 "lastEditedAt" => "2021-02-21T15:44:56.868000Z",
                 "changeImageEditProps" => %{
                   "originalImageUrl" => "original url",
                   "imageUrl" => "some url"
                 }
               },
               %{
                 "domSelector" => %{
                   "xpathNode" => "div",
                   "xpathFrames" => []
                 },
                 "frameSelectors" => ["iframe"],
                 "cssSelector" => ".link",
                 "id" => results |> Enum.at(4) |> Map.get("id"),
                 "kind" => "LINK",
                 "lastEditedAt" => "2021-02-21T15:44:56.868000Z",
                 "linkEditProps" => %{
                   "destination" => %{"href" => "https://www.google.com", "target" => "NEW_TAB"}
                 }
               },
               %{
                 "domSelector" => %{
                   "xpathNode" => "div",
                   "xpathFrames" => []
                 },
                 "frameSelectors" => ["iframe"],
                 "cssSelector" => ".link",
                 "id" => results |> Enum.at(5) |> Map.get("id"),
                 "kind" => "LINK",
                 "lastEditedAt" => "2021-02-21T15:44:56.868000Z",
                 "linkEditProps" => %{
                   "destination" => %{"delayMs" => 1000, "screen" => %{"id" => screen.id}}
                 }
               },
               %{
                 "domSelector" => %{
                   "xpathNode" => "div",
                   "xpathFrames" => []
                 },
                 "frameSelectors" => ["iframe"],
                 "cssSelector" => ".scroll",
                 "id" => results |> Enum.at(6) |> Map.get("id"),
                 "kind" => "SCROLL",
                 "lastEditedAt" => "2021-02-21T15:44:56.868000Z",
                 "scrollEditProps" => %{
                   "top" => 125.0,
                   "left" => 0.0
                 }
               },
               %{
                 "domSelector" => %{
                   "xpathNode" => "div",
                   "xpathFrames" => []
                 },
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
                 "domSelector" => %{
                   "xpathNode" => "div",
                   "xpathFrames" => []
                 },
                 "frameSelectors" => ["iframe"],
                 "cssSelector" => ".bind",
                 "id" => results |> Enum.at(8) |> Map.get("id"),
                 "kind" => "BINDING",
                 "lastEditedAt" => "2021-02-21T15:44:56.868000Z",
                 "bindingEditProps" => %{
                   "program" =>
                     "{\"@astVersion\":\"Ast_20210525\",\"@envVersion\":\"Env_20210525\",\"@expression\":{\"@args\":[{\"@name\":\"name\",\"@value\":\"name test\"},{\"@name\":\"defaultValue\",\"@value\":\"default value\"},{\"@name\":\"description\",\"@value\":\"desc\"}],\"@fnName\":\"PUBLIC_FIELD\",\"@id\":\"ef44f562-1d5e-4d38-bf59-7ef7a402380d\",\"@type\":\"Call\"}}",
                   "originalText" => "original dom element"
                 }
               }
             ]

      storyline = Storylines.get_storyline!(screen.flow.storyline_id)
      assert DateTime.compare(storyline.last_edited, last_edited_before_adding_edits) == :gt
    end

    test "add text edit with empty string", %{
      context: %{current_member: member} = context
    } do
      screen =
        Api.StorylinesFixtures.public_storyline_fixture(member)
        |> Api.StorylinesFixtures.screen_fixture()

      result =
        query_gql_by(:add_edits_dynamic,
          variables: %{
            "screenId" => screen.id,
            "edits" => [
              %{
                "domSelector" => nil,
                "frameSelectors" => ["iframe"],
                "cssSelector" => "asdasd",
                "lastEditedAt" => "2021-02-21T15:44:56.868Z",
                "kind" => "TEXT",
                "textEditProps" => %{"originalText" => "original text", "text" => ""}
              }
            ]
          },
          context: context
        )

      assert {:ok,
              %{
                data: %{
                  "addEditsToScreen" => [
                    %{
                      "cssSelector" => "asdasd",
                      "frameSelectors" => ["iframe"],
                      "id" => _,
                      "kind" => "TEXT",
                      "lastEditedAt" => "2021-02-21T15:44:56.868000Z",
                      "textEditProps" => %{"originalText" => "original text", "text" => ""}
                    }
                  ]
                }
              }} = result
    end

    test "authorization", %{
      context: %{current_member: member} = context
    } do
      screen =
        Api.StorylinesFixtures.public_storyline_fixture(member)
        |> Api.StorylinesFixtures.screen_fixture()

      TestAccess.assert_roles(
        &query_gql_by(
          :add_edits,
          variables: %{"screenId" => screen.id},
          context: Map.put(context, :current_member, &1)
        ),
        context.current_member,
        %TestAccess{viewer: false, presenter: true, editor: true, company_admin: true}
      )
    end
  end
end
