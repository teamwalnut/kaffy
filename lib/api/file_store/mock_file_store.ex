defmodule Api.FileStore.Mock do
  @behaviour Api.FileStore
  @moduledoc """
  Mock FileStore module. This can be populated with mock responses for certain inputs. This is used
  in the test environment.
  """

  @impl Api.FileStore
  def upload_asset(_path, _contents, _content_type) do
    :ok
  end

  @impl Api.FileStore
  def upload_artifact(_path, _contents, _content_type) do
    :ok
  end
end
