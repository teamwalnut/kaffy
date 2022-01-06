defmodule ApiWeb.AssetsTest do
  use ApiWeb.ConnCase, async: true
  require Logger
  alias Api.{Assets, AssetsFixtures}
  import Hammox
  import Tesla.Mock
  import ExUnit.CaptureLog

  # Make sure mocks are verified when the test exits
  setup :verify_on_exit!

  setup [:register_and_log_in_user]

  setup do
    mock(fn
      %{method: :get, url: "http://example.com/hello"} ->
        %Tesla.Env{
          status: 200,
          headers: [{"content-type", "text/html"}, {"content-length", "123"}],
          body: ["hello", "world"]
        }

      %{method: :get, url: "http://example.com/bad"} ->
        %Tesla.Env{
          status: 404,
          headers: [],
          body: []
        }

      %{method: :get, url: "http://example.com/exception"} ->
        {:error, "bad bad bad"}
    end)

    :ok
  end

  describe "POST /api/assets/filter_existing" do
    test "It returns the filtered list correctly", %{conn: conn} do
      asset1 = AssetsFixtures.asset1()
      asset2 = AssetsFixtures.asset2()
      {:ok, asset1} = Assets.register(asset1)

      conn = post(conn, "/api/assets/filter_existing", %{assets: [asset1.name, asset2.name]})

      assert response(conn, 200) =~ "[\"some_name2\"]"
    end
  end

  describe "GET /api/assets" do
    test "It streams the signed URL with proper headers", %{conn: conn} do
      Api.S3Mock
      |> expect(:gen_signed_url, fn _, :get ->
        {:ok, "http://example.com/hello"}
      end)

      conn = get(conn, "/api/assets", %{name: "some name"})

      assert response(conn, 200) == "helloworld"

      headers = Enum.into(conn.resp_headers, %{})
      assert headers["access-control-allow-origin"] == "*"
    end

    test "It handles not 200 responses from S3 correctly", %{conn: conn} do
      Api.S3Mock
      |> expect(:gen_signed_url, fn _, :get ->
        {:ok, "http://example.com/bad"}
      end)

      assert capture_log(fn ->
               conn = get(conn, "/api/assets", %{name: "some name"})

               assert response(conn, 404) == ""

               headers = Enum.into(conn.resp_headers, %{})
               assert headers["access-control-allow-origin"] == "*"
             end) =~ "Not 200 response while fetching assets"
    end

    test "It handles Tesla errors correctly", %{conn: conn} do
      Api.S3Mock
      |> expect(:gen_signed_url, fn _, :get ->
        {:ok, "http://example.com/exception"}
      end)

      assert capture_log(fn ->
               conn = get(conn, "/api/assets", %{name: "some name"})

               assert response(conn, 500) == "Error fetching asset"

               headers = Enum.into(conn.resp_headers, %{})
               assert headers["access-control-allow-origin"] == "*"
             end) =~ "Error fetching asset"
    end
  end

  describe "POST /api/assets/register" do
    test "It registers the asset", %{conn: conn} do
      asset1 = AssetsFixtures.asset1()

      conn = post(conn, "/api/assets/register", %{name: asset1.name})

      assert response(conn, 200) == "{\"ok\":\"ok\"}"
    end

    test "It registers multiple assets", %{conn: conn} do
      asset1 = AssetsFixtures.asset1()
      asset2 = AssetsFixtures.asset2()

      conn = post(conn, "/api/assets/register", %{names: [asset1.name, asset2.name]})

      assert response(conn, 200) == "{\"ok\":\"ok\"}"
    end
  end
end
