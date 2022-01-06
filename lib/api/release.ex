defmodule Api.Release do
  @moduledoc """
  note(itay): This module is used in our production build to run the migrations
  as recommended by https://hexdocs.pm/phoenix/releases.html#ecto-migrations-and-custom-commands

  To use change the run command of our docker image.
  Equivalent of `mix ecto.create` => ["/bin/api", "eval", "\"Api.Release.createdb\""]
  Equivalent of `mix ecto.migrate` => ["/bin/api", "eval", "\"Api.Release.migrate\""]
  """
  @app :api

  def createdb do
    IO.puts("Starting dependencies...")
    load_app()

    for repo <- repos() do
      :ok = ensure_repo_created(repo)
    end

    IO.puts("createdb task done!")
  end

  defp ensure_repo_created(repo) do
    IO.puts("create #{inspect(repo)} database if it doesn't exist")

    case repo.__adapter__.storage_up(repo.config) do
      :ok ->
        IO.puts("Repo created successfully")
        :ok

      {:error, :already_up} ->
        IO.puts("Error: Repo already up")
        :ok

      {:error, term} ->
        IO.puts("Error!")
        IO.puts(term)
        {:error, term}
    end
  end

  def migrate do
    IO.puts("Starting dependencies...")
    load_app()

    for repo <- repos() do
      IO.puts("Running schema migrations")
      IO.puts(repo)
      {:ok, _, _} = Ecto.Migrator.with_repo(repo, &Ecto.Migrator.run(&1, :up, all: true))
    end

    IO.puts("Migrate finished successfully")
  end

  def migrate_manual do
    IO.puts("Starting dependencies...")
    load_app()

    for repo <- repos() do
      path = priv_path_for(repo, "manual_migrations")
      IO.puts("Running manual migrations from path: #{path}")
      IO.puts(repo)
      {:ok, _, _} = Ecto.Migrator.with_repo(repo, &Ecto.Migrator.run(&1, path, :up, all: true))
    end

    IO.puts("Manual migration finished successfully")
  end

  def rollback(repo, version) do
    load_app()
    {:ok, _, _} = Ecto.Migrator.with_repo(repo, &Ecto.Migrator.run(&1, :down, to: version))
  end

  defp repos do
    Application.fetch_env!(@app, :ecto_repos)
  end

  defp load_app do
    Application.load(@app)
    Enum.each([:postgrex, :ecto, :ecto_sql], &Application.ensure_all_started/1)
  end

  defp priv_path_for(repo, filename) do
    app = Keyword.get(repo.config(), :otp_app)

    repo_underscore =
      repo
      |> Module.split()
      |> List.last()
      |> Macro.underscore()

    priv_dir = "#{:code.priv_dir(app)}"

    Path.join([priv_dir, repo_underscore, filename])
  end
end
