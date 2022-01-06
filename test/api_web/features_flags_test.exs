defmodule ApiWeb.FeaturesFlagsTest do
  use ApiWeb.ConnCase, async: true

  describe "FeaturesFlagsTest" do
    test "it should return the correct sdk_key and configuration" do
      sdk_key = String.to_charlist(Application.get_env(:api, :ld_sdk_key))

      {^sdk_key, %{stream: true}} =
        Agent.get(ApiWeb.FeaturesFlags.Provider.Stub, fn state -> state end)
    end
  end
end
