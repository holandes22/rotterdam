use Mix.Config

# For development, we disable any cache and enable
# debugging and code reloading.
#
# The watchers configuration can be used to run external
# watchers to your application. For example, we use it
# with brunch.io to recompile .js and .css sources.
config :rotterdam, Rotterdam.Endpoint,
  http: [port: 4000],
  debug_errors: true,
  code_reloader: true,
  check_origin: false,
  watchers: [npm: ["run", "watch",
                    cd: Path.expand("../", __DIR__)]]


# Watch static and templates for browser reloading.
config :rotterdam, Rotterdam.Endpoint,
  live_reload: [
    patterns: [
      ~r{priv/static/.*(js|css|png|jpeg|jpg|gif|svg)$},
      ~r{priv/gettext/.*(po)$},
      ~r{web/views/.*(ex)$},
      ~r{web/templates/.*(eex)$}
    ]
  ]

# Do not include metadata nor timestamps in development logs
config :logger, :console, format: "[$level] $message\n"

# Set a higher stacktrace during development. Avoid configuring such
# in production as building large stacktraces may be expensive.
config :phoenix, :stacktrace_depth, 20

# Configure your database
config :rotterdam, Rotterdam.Repo,
  adapter: Ecto.Adapters.Postgres,
  username: "postgres",
  password: "postgres",
  database: "rotterdam_dev",
  hostname: "localhost",
  pool_size: 10

config :rotterdam,
    managed_nodes: [
      %{
        id: :node1,
        label: "Manager",
        role: :manager,
        host: "192.168.99.100",
        cert_path: "/home/pablo/.docker/machine/machines/cluster1-node1"
      },
      %{
        id: :node2,
        label: "Worker1",
        role: :worker,
        host: "192.168.99.101",
        cert_path: "/home/pablo/.docker/machine/machines/cluster1-node2"
      }
    ]
