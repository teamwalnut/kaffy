defmodule Kaffy.ResourceQueryTest do
  use ExUnit.Case, async: true

  alias Kaffy.ResourceQuery
  alias KaffyTest.Admin.PersonAdmin
  alias KaffyTest.Schemas.Person

  @resource [schema: Person, admin: PersonAdmin]

  describe "get_ordering/2" do
    test "allows persisted schema fields and supported directions" do
      assert ResourceQuery.get_ordering(@resource, %{"_of" => "name", "_ow" => "asc"}) ==
               [asc: :name]
    end

    test "falls back to resource ordering for display-only fields" do
      assert ResourceQuery.get_ordering(@resource, %{"_of" => "user", "_ow" => "asc"}) ==
               [desc: :id]
    end

    test "falls back to resource ordering for unsupported directions" do
      assert ResourceQuery.get_ordering(@resource, %{"_of" => "name", "_ow" => "sideways"}) ==
               [desc: :id]
    end

    test "does not raise for unknown atoms" do
      assert ResourceQuery.get_ordering(@resource, %{
               "_of" => "definitely_not_an_existing_atom",
               "_ow" => "asc"
             }) == [desc: :id]
    end
  end

  describe "sortable_field?/2" do
    test "only persisted schema fields are sortable" do
      assert ResourceQuery.sortable_field?(@resource, :name)
      refute ResourceQuery.sortable_field?(@resource, :pets)
      refute ResourceQuery.sortable_field?(@resource, :user)
    end
  end
end
