# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.

# General application configuration
use Mix.Config

config :fset,
  ecto_repos: [Fset.Repo]

# Configures the endpoint
config :fset, FsetWeb.Endpoint,
  url: [host: "localhost"],
  secret_key_base: "nhcukLg3rzRPeB5ZUy3Zx0DO0GpxZG2DxwMoayoD8XVLvR8bwkC7XohwSbVStXqJ",
  render_errors: [view: FsetWeb.ErrorView, accepts: ~w(html json), layout: false],
  pubsub_server: Fset.PubSub,
  live_view: [signing_salt: "qofvwfh4"]

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# Use Jason for JSON parsing in Phoenix
config :phoenix, :json_library, Jason

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{Mix.env()}.exs"
