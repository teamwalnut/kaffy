defmodule Api.DemoCustomizationsTest do
  alias Api.Storylines.Editing

  defp create_binding_edit(screen_id, var_name) do
    fake_program_embed =
      "{\"@astVersion\":\"Ast_20210525\",\"@envVersion\":\"Env_20210525\",\"@expression\":{\"@args\":[{\"@name\":\"name\",\"@value\":\"#{var_name}\"},{\"@name\":\"defaultValue\",\"@value\":\"default value\"},{\"@name\":\"description\",\"@value\":\"desc\"}],\"@fnName\":\"PUBLIC_FIELD\",\"@id\":\"ef44f562-1d5e-4d38-bf59-7ef7a402380d\",\"@type\":\"Call\"}}"

    props = %{
      kind: :binding,
      dom_selector: nil,
      css_selector: "some css selector",
      frame_selectors: ["iframe"],
      last_edited_at: DateTime.utc_now(),
      binding_edit_props: %{
        original_text: "original text",
        program_embed: fake_program_embed
      }
    }

    {:ok, edit} = Editing.add_edit(screen_id, props)
    edit
  end

  use Api.DataCase, async: true

  alias Api.Storylines.Demos.DemoCustomizations

  setup [
    :setup_company,
    :setup_user,
    :setup_member,
    :setup_public_storyline
  ]

  @variable %{
    name: "client-name",
    description: "The client name",
    kind: :text,
    default_value: "The default value"
  }

  describe "create_or_update_variable/3" do
    test "it returns :ok with valid data", %{
      public_storyline: public_storyline,
      member: member
    } do
      {:ok, _variable} =
        DemoCustomizations.create_or_update_variable(
          public_storyline.id,
          @variable,
          member
        )
    end

    test "it manages to update description for existing variable", %{
      public_storyline: public_storyline,
      member: member
    } do
      {:ok, _variable} =
        DemoCustomizations.create_or_update_variable(
          public_storyline.id,
          @variable,
          member
        )

      {:ok, variable} =
        DemoCustomizations.create_or_update_variable(
          public_storyline.id,
          Map.merge(@variable, %{description: "update", default_value: "update"}),
          member
        )

      assert variable.description == "update"
      assert variable.default_value == "update"
    end

    test "it manages to create variable with same name for different storyline", %{
      public_storyline: public_storyline,
      member: member
    } do
      another_storyline = public_storyline_fixture(member)

      {:ok, variable1} =
        DemoCustomizations.create_or_update_variable(
          public_storyline.id,
          @variable,
          member
        )

      {:ok, variable2} =
        DemoCustomizations.create_or_update_variable(
          another_storyline.id,
          @variable,
          member
        )

      refute variable1.id == variable2.id
    end

    test "it returns :error for unauthorized actor", %{
      public_storyline: public_storyline,
      company: company,
      member: _member
    } do
      another_user = Api.AccountsFixtures.user_fixture()

      {:ok, another_member} =
        Api.Companies.add_member(another_user.id, company, %{role: :presenter})

      {:error, :unauthorized} =
        DemoCustomizations.create_or_update_variable(
          public_storyline.id,
          @variable,
          another_member
        )
    end
  end

  describe "list_variables/3" do
    test "it returns variables and filters variables without binding edits", %{
      public_storyline: public_storyline,
      member: member
    } do
      screen = Api.StorylinesFixtures.screen_fixture(public_storyline)

      {:ok, _variable} =
        DemoCustomizations.create_or_update_variable(
          public_storyline.id,
          @variable,
          member
        )

      {:ok, _variable} =
        DemoCustomizations.create_or_update_variable(
          public_storyline.id,
          Map.merge(@variable, %{name: "test2"}),
          member
        )

      create_binding_edit(screen.id, @variable.name)

      {:ok, variables} =
        DemoCustomizations.list_variables(
          public_storyline.id,
          member
        )

      assert Enum.count(variables) == 1
      assert Enum.at(variables, 0).name == @variable.name
    end

    test "it returns :error for unauthorized actor", %{
      public_storyline: public_storyline,
      company: company,
      member: _member
    } do
      another_user = Api.AccountsFixtures.user_fixture()
      {:ok, another_member} = Api.Companies.add_member(another_user.id, company, %{role: :viewer})

      {:error, :unauthorized} =
        DemoCustomizations.create_or_update_variable(
          public_storyline.id,
          @variable,
          another_member
        )
    end
  end
end
