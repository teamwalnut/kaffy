defmodule ApiWeb.Schema.DOMTypes do
  @moduledoc false
  use Absinthe.Schema.Notation
  require Logger

  @desc "A selector used to find things in the DOM"
  object :dom_selector do
    @desc "The XPath representation of a DOM Selector"
    field(:xpath_node, non_null(:string))
    field(:xpath_frames, non_null(list_of(non_null(:string))), default_value: [])
  end

  input_object :dom_selector_input do
    field(:xpath_node, :string)
    field(:xpath_frames, list_of(non_null(:string)), default_value: [])
  end
end
