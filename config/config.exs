# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.
use Mix.Config

# General application configuration
config :rotterdam,
  ecto_repos: [Rotterdam.Repo]

# Configures the endpoint
config :rotterdam, Rotterdam.Endpoint,
  url: [host: "localhost"],
  secret_key_base: "v3dx4TtDoYmtp8z1MNio5NZ4kdKyc8Y20kWjMmpTzM7T6ekqDTYbj/IKS4PuqJDR",
  render_errors: [view: Rotterdam.ErrorView, accepts: ~w(html json)],
  pubsub: [name: Rotterdam.PubSub,
           adapter: Phoenix.PubSub.PG2]

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{Mix.env}.exs"
