defmodule Api.AssetsTest do
  use Api.DataCase, async: true
  alias Api.{Assets, AssetsFixtures}

  describe "register/3" do
    test "saves an asset correctly without hash" do
      assert {:ok, asset} = Assets.register(AssetsFixtures.asset1())
      assert asset.name == "some_name"
    end

    test "fails if asset with same uri and hash exists" do
      {:ok, _asset} = Assets.register(AssetsFixtures.asset1())
      assert {:error, error_changeset} = Assets.register(AssetsFixtures.asset1())

      assert error_changeset.errors == [
               name: {
                 "has already been taken",
                 [validation: :unsafe_unique, fields: [:name]]
               }
             ]
    end
  end

  describe "filter_existing/1" do
    test "it filters out existing assets" do
      asset3 = AssetsFixtures.asset3()
      {:ok, asset1} = Assets.register(AssetsFixtures.asset1())
      {:ok, asset2} = Assets.register(AssetsFixtures.asset2())

      filtered =
        Assets.filter_existing([
          "#{asset1.name}",
          "#{asset2.name}",
          "#{asset3.name}"
        ])

      assert filtered == [
               AssetsFixtures.asset3().name
             ]
    end

    test "it ignores fragment while checking for assets" do
      asset3 = AssetsFixtures.asset3()
      {:ok, asset1} = Assets.register(AssetsFixtures.asset1())
      {:ok, asset2} = Assets.register(AssetsFixtures.asset2())

      filtered =
        Assets.filter_existing([
          "#{asset1.name}",
          "#{asset2.name}#withFragment",
          "#{asset3.name}"
        ])

      assert filtered == [
               AssetsFixtures.asset3().name
             ]
    end
  end
end
