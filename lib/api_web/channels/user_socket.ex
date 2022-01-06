defmodule ApiWeb.UserSocket do
  use Phoenix.Socket
  require Logger

  ## Channels
  channel("editor:*", ApiWeb.EditorChannel)

  # Socket params are passed from the client and can
  # be used to verify and authenticate a user. After
  # verification, you can put default assigns into
  # the socket that will be set for all channels, ie
  #
  #     {:ok, assign(socket, :user_id, verified_user_id)}
  #
  # To deny connection, return `:error`.
  #
  # See `Phoenix.Token` documentation for examples in
  # performing token verification on connect.
  @impl true
  def connect(
        %{"editor_session_id" => editor_session_id, "user_full_name" => user_full_name},
        %Phoenix.Socket{} = socket,
        _connect_info
      )
      when is_binary(editor_session_id) do
    {:ok, assign(socket, user_full_name: user_full_name, editor_session_id: editor_session_id)}
  end

  @impl true
  def connect(_params, _socket, _connect_info) do
    :error
  end

  # Socket id's are topics that allow you to identify all sockets for a given user:
  # Would allow you to broadcast a "disconnect" event and terminate
  # all active sockets and channels for a given user:
  #
  #     ApiWeb.Endpoint.broadcast("user_socket:#{user.id}", "disconnect", %{})
  #
  # Returning `nil` makes this socket anonymous.
  @impl true
  def id(socket), do: "user_socket:#{socket.assigns[:editor_session_id]}"
end
