defmodule ApiWeb.EditorChannel do
  @moduledoc """
  Basic channel for editor users, currently only used to track who openes the editor
  """
  use ApiWeb, :channel
  alias ApiWeb.Presence
  require Logger

  def join("editor:" <> _storyline_id, _params, socket) do
    send(self(), :after_join)
    {:ok, socket}
  end

  def handle_info(:after_join, socket) do
    {:ok, _} =
      Presence.track(socket, socket.assigns.editor_session_id, %{
        online_at: inspect(System.system_time(:second)),
        editor_session_id: socket.assigns.editor_session_id,
        full_name: socket.assigns.user_full_name
      })

    push(socket, "presence_state", Presence.list(socket))
    {:noreply, socket}
  end
end
