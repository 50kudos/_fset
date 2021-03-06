defmodule Fset.MixProject do
  use Mix.Project

  def project do
    [
      app: :fset,
      version: "0.1.0",
      elixir: "~> 1.10",
      elixirc_paths: elixirc_paths(Mix.env()),
      compilers: [:phoenix, :gettext] ++ Mix.compilers(),
      start_permanent: Mix.env() == :prod,
      aliases: aliases(),
      deps: deps(),

      # Docs
      name: "Fset",
      source_url: "https://github.com/50kudos/fset",
      homepage_url: "https://fsetapp.com",
      docs: [
        main: "Fset"
        # extras: ["README.md"]
      ]
    ]
  end

  # Configuration for the OTP application.
  #
  # Type `mix help compile.app` for more information.
  def application do
    [
      mod: {Fset.Application, []},
      extra_applications: [:logger, :runtime_tools]
    ]
  end

  # Specifies which paths to compile per environment.
  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  # Specifies your project dependencies.
  #
  # Type `mix help deps` for examples and options.
  defp deps do
    [
      {:bcrypt_elixir, "~> 2.0"},
      {:phoenix, "~> 1.5.7"},
      {:phoenix_ecto, "~> 4.2"},
      {:ecto, "~> 3.5.0-rc.0", override: true},
      {:ecto_sql, "~> 3.5.0-rc.0"},
      {:postgrex, ">= 0.0.0"},
      {:phoenix_live_view, "~> 0.15.1",
       github: "phoenixframework/phoenix_live_view", override: true},
      {:floki, ">= 0.0.0", only: :test},
      {:phoenix_html, "~> 2.11", github: "phoenixframework/phoenix_html", override: true},
      {:phoenix_live_reload, "~> 1.2", only: :dev},
      {:phoenix_live_dashboard, "~> 0.3.0"},
      {:telemetry_metrics, "~> 0.4"},
      {:telemetry_poller, "~> 0.4"},
      {:gettext, "~> 0.11"},
      {:jason, "~> 1.0"},
      {:plug_cowboy, "~> 2.0"},
      {:cloak_ecto, "~> 1.0.1"},
      {:phx_gen_auth, "~> 0.4.0", only: [:dev], runtime: false},
      {:stream_data, "~> 0.4"},
      {:randex, "~> 0.4"},
      {:libcluster, "~> 3.2"},
      {:ex_doc, "~> 0.22", only: :dev, runtime: false},
      {:finch, "~> 0.3"}
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
      setup: ["deps.get", "ecto.setup", "cmd npm install --prefix assets"],
      "ecto.setup": ["ecto.create", "ecto.migrate", "run priv/repo/seeds.exs"],
      "ecto.reset": ["ecto.drop", "ecto.setup"],
      test: ["ecto.create --quiet", "ecto.migrate --quiet", "test"]
    ]
  end
end
