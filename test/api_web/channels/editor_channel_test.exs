defmodule ApiWeb.EditorChannelTest do
  use ApiWeb.ChannelCase

  @editor_session1 "session1"
  @editor_session2 "session2"

  setup do
    user1 = Api.AccountsFixtures.user_fixture()
    user2 = Api.AccountsFixtures.user_fixture()

    {:ok, socket} =
      connect(
        ApiWeb.UserSocket,
        %{
          "user_full_name" => "#{user1.first_name} #{user1.last_name}",
          "editor_session_id" => @editor_session1
        },
        %{}
      )

    {:ok, socket2} =
      connect(
        ApiWeb.UserSocket,
        %{
          "user_full_name" => "#{user2.first_name} #{user2.last_name}",
          "editor_session_id" => @editor_session2
        },
        %{}
      )

    {:ok, _, socket} = subscribe_and_join(socket, "editor:123", %{})
    {:ok, _, _socket2} = subscribe_and_join(socket2, "editor:123", %{})

    on_exit(fn ->
      for pid <- ApiWeb.Presence.fetchers_pids() do
        ref = Process.monitor(pid)
        assert_receive {:DOWN, ^ref, _, _, _}, 1000
      end
    end)

    %{socket: socket}
  end

  describe "EditorChannel" do
    test "It tracks connections correctly", %{socket: socket} do
      assert ApiWeb.Presence.list(socket) |> Enum.count() == 2
      user1_metas = ApiWeb.Presence.list(socket)[@editor_session1][:metas]
      assert user1_metas |> Enum.count() == 1
      assert user1_metas |> Enum.at(0) |> Map.get(:editor_session_id) == @editor_session1
      assert user1_metas |> Enum.at(0) |> Map.get(:full_name) == "my name is slim shady"

      user2_metas = ApiWeb.Presence.list(socket)[@editor_session2][:metas]
      assert user2_metas |> Enum.count() == 1
      assert user2_metas |> Enum.at(0) |> Map.get(:editor_session_id) == @editor_session2
      assert user2_metas |> Enum.at(0) |> Map.get(:full_name) == "my name is slim shady"
    end
  end
end
