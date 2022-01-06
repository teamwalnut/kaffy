defmodule Api.Settings.Cascade do
  @moduledoc """
  This module is responsible for cascading attributes from multiple maps of attirbutes.
  """

  @doc """
  Recieves 3 maps and an attribute.
  It then tries to fetch that attribute from each map in the following order:
  First, Second and Default.

  ## Examples

      iex> three_way_merge(%{"foo" => 1}, %{"foo" => 2}, %{"foo" => 3}, "foo")
      1

      iex> three_way_merge(%{"bar" => 1}, %{"foo" => 2}, %{"foo" => 3}, "foo")
      2

      iex> three_way_merge(%{"bar" => 1}, %{"foobar" => 2}, %{"foo" => 3}, "foo")
      3
  """
  def three_way_merge(first, second, default, attr) do
    case {first && Map.get(first, attr), second && Map.get(second, attr), Map.get(default, attr)} do
      {nil, nil, default} -> default
      {nil, second, _} -> second
      {first, _, _} -> first
    end
  end
end
