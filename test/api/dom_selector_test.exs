defmodule Api.DOMSelectorTest do
  @moduledoc false
  use ExUnit.Case

  describe "DOMSelector" do
    test "we can create a DOM Selector from an XPath" do
      xpath_node = "//hello/world"

      assert %Ecto.Changeset{
               changes: %{
                 xpath_node: ^xpath_node
               },
               errors: [],
               valid?: true
             } = Api.DOMSelector.from_xpath(xpath_node, [])
    end
  end
end
