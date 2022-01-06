defmodule Api.MixProject do
  use Mix.Project

  def project do
    [
      app: :api,
      version: "0.1.0",
      elixir: "~> 1.12.3",
      elixirc_paths: elixirc_paths(Mix.env()),
      test_coverage: [tool: ExCoveralls],
      preferred_cli_env: [
        coveralls: :test,
        "coveralls.detail": :test,
        "coveralls.github": :test,
        "coveralls.post": :test,
        "coveralls.html": :test,
        "test.ci": :test
      ],
      compilers: compilers(Mix.env()),
      start_permanent: Mix.env() == :prod,
      aliases: aliases(),
      releases: [
        api: [
          validate_compile_env: false
        ]
      ],
      dialyzer: dialyzer(),
      deps: deps()
    ]
  end

  defp compilers(env) when env in [:dev, :test] do
    [:phoenix, :gettext] ++ Mix.compilers() ++ [:graphql_schema_sdl]
  end

  defp compilers(_) do
    [:phoenix, :gettext] ++ Mix.compilers()
  end

  # Configuration for the OTP application.
  #
  # Type `mix help compile.app` for more information.
  def application do
    [
      mod: {ApiApplication, []},
      extra_applications: [:logger, :runtime_tools]
    ]
  end

  # Specifies which paths to compile per environment.
  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  defp dialyzer do
    [
      plt_core_path: "priv/plts",
      plt_file: {:no_warn, "priv/plts/dialyzer.plt"},
      plt_add_apps: [:mix]
    ]
  end

  # Specifies your project dependencies.
  #
  # Type `mix help deps` for examples and options.
  defp deps do
    [
      {:phoenix, "~> 1.6"},
      {:configparser_ex, "~> 4.0"},
      {:phoenix_ecto, "~> 4.1"},
      {:ecto_sql, "~> 3.4"},
      {:postgrex, ">= 0.0.0"},
      {:phoenix_live_dashboard, "~> 0.5"},
      {:telemetry_metrics, "~> 0.6"},
      {:telemetry_poller, "~> 0.5"},
      {:phoenix_html, "~> 3.0"},
      {:jason, "~> 1.0"},
      {:joken, "~> 2.0"},
      {:plug_cowboy, "~> 2.1"},
      {:bcrypt_elixir, "~> 2.0"},
      {:gettext, "~> 0.11"},
      {:absinthe, "~> 1.6"},
      {:absinthe_plug, "~> 1.5"},
      {:dataloader, "~> 1.0.0"},
      {:cors_plug, "~> 2.0"},
      {:mojito, "~> 0.7.9"},
      {:tesla, "~> 1.4.0"},
      {:mint, "~> 1.2"},
      {:ex_aws, "~> 2.2"},
      {:ex_aws_s3, "~> 2.0"},
      {:phoenix_pubsub_redis, "~> 3.0"},
      {:sentry, "~> 8.0"},
      {:ecto_enum_migration, "~> 0.3.1"},
      {:logger_json, "~> 4.0"},
      {:bamboo, "~> 2.0"},
      {:bamboo_phoenix, "~> 1.0"},
      {:polymorphic_embed, "~> 1.4"},
      {:ecto_psql_extras, "~> 0.7"},
      {:httpoison, "~> 1.7"},
      {:spandex, "~> 3.1.0"},
      {:spandex_ecto, "~> 0.7.0"},
      {:spandex_phoenix, "~> 1.0.5"},
      {:spandex_datadog, "~> 1.2.0"},
      {:segment, "~> 0.2.5"},
      {:bodyguard, "~> 2.4.1"},
      {:ecto_fields, "~> 1.3.0"},
      {:oban, "~> 2.10"},
      {:workos,
       git: "https://github.com/workos-inc/workos-elixir",
       ref: "bccc2aa0927d249fc27e37cd429d1d62a3e237ec"},
      {:ldclient, "~> 1.3", hex: :launchdarkly_server_sdk},
      # note(itay): We need to explicitly override the cowlib version as :ldclient depends on an earlier
      # version
      {:cowlib, "~> 2.11.0", override: true},
      # Our admin interface!
      {:kaffy,
       git: "https://github.com/teamwalnut/kaffy", ref: "f41696bd4de328c81ae87eb6e9d795ffc1c30756"},
      # =====================TEST-STUFF==================================================
      {:sobelow, "~> 0.8", only: [:dev, :test]},
      {:mix_test_watch, "~> 1.0", only: :dev, runtime: false},
      {:ex_unit_notifier, "~> 1.0", only: :test},
      {:credo, "~> 1.4", only: [:dev, :test], runtime: false},
      {:hammox, "~> 0.2", only: :test},
      {:excoveralls, "~> 0.10", only: :test},
      {:wormwood, "~>0.1", only: :test},
      {:telemetry_metrics_statsd, "~> 0.6.0"},
      {:dialyxir, "~> 1.0", only: [:test, :dev], runtime: false},
      {:snapshy, "~> 0.2", only: [:test, :dev]}
    ]
  end

  # Aliases are shortcuts or tasks specific to the current project.
  # For example, to install project dependencies and perform other setup tasks, run:
  #
  #     $ mix setup
  #
  # See the documentation for `Mix` for more info on aliases.
  defp aliases do
    [
      sentry_recompile: ["compile", "deps.compile sentry --force"],
      setup: ["deps.get", "ecto.setup"],
      "ecto.migrate_all": [
        "ecto.migrate --migrations-path=priv/repo/migrations --migrations-path=priv/repo/manual_migrations"
      ],
      "ecto.migrate_manual": [
        "ecto.migrate --migrations-path=priv/repo/manual_migrations"
      ],
      "ecto.setup": ["ecto.create", "ecto.migrate", "run priv/repo/seeds.exs"],
      "ecto.reset": ["ecto.drop", "ecto.setup"],
      "gen.manual_migration": ["ecto.gen.migration --migrations-path=priv/repo/manual_migrations"],
      test: [
        "ecto.create --quiet",
        "ecto.migrate --quiet",
        "cmd mix compile --all-warnings",
        "test --warnings-as-errors",
        "format --check-formatted",
        "credo --strict"
      ],
      "test.ci": [
        "ecto.create --quiet",
        "ecto.migrate --quiet",
        # Note(Danni): only way i found where it actually fails the process,
        # using without the cmd doesnt seem to work
        "cmd mix compile --all-warnings --warnings-as-errors",
        "format --check-formatted",
        "credo --strict",
        "hex.audit",
        "deps.unlock --check-unused",
        run_tests()
      ]
    ]
  end

  defp run_tests do
    if System.get_env("CI", "false") == "true" do
      "coveralls.github --color --raise --warnings-as-errors"
    else
      "coveralls.html --color --raise --warnings-as-errors"
    end
  end
end
