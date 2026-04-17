# This file is responsible for configuring your umbrella
# and **all applications** and their dependencies with the
# help of the Config module.
#
# Note that all applications in your umbrella share the
# same configuration and dependencies, which is why they
# all use the same configuration file. If you want different
# configurations or dependencies per app, it is best to
# move said applications out of the umbrella.
# This file is responsible for configuring your application
# and its dependencies with the aid of the Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.

# General application configuration
import Config

config :timberee,
  generators: [timestamp_type: :utc_datetime]

config :scenic, :assets, module: TimbereeScenic.Assets

config :timberee_scenic, :adjustment, width: -280, height: -380

config :timberee_scenic, :viewport,
  name: :main_viewport,
  size: {800, 480},
  theme: :dark,
  default_scene: TimbereeScenic.Scene.Timber,
  drivers: [
    [
      module: Scenic.Driver.Local,
      name: :local,
      window: [resizeable: false, title: "timberee"],
      on_close: :stop_system
    ]
  ]

# Configures the endpoint
config :timberee, TimbereeWeb.Endpoint,
  url: [host: "localhost"],
  adapter: Bandit.PhoenixAdapter,
  render_errors: [
    formats: [html: TimbereeWeb.ErrorHTML, json: TimbereeWeb.ErrorJSON],
    layout: false
  ],
  pubsub_server: Timberee.PubSub,
  live_view: [signing_salt: "Eqp4dUEa"]

# Configure esbuild (the version is required)
config :esbuild,
  version: "0.25.4",
  timberee: [
    args:
      ~w(js/app.js --bundle --target=es2022 --outdir=../priv/static/assets/js --external:/fonts/* --external:/images/* --alias:@=.),
    cd: Path.expand("../assets", __DIR__),
    env: %{"NODE_PATH" => [Path.expand("../deps", __DIR__), Mix.Project.build_path()]}
  ]

# Configure tailwind (the version is required)
config :tailwind,
  version: "4.1.7",
  timberee: [
    args: ~w(
      --input=assets/css/app.css
      --output=priv/static/assets/css/app.css
    ),
    cd: Path.expand("../assets", __DIR__)
  ]

# Configures Elixir's Logger
config :logger, :default_formatter,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# Use Jason for JSON parsing in Phoenix
config :phoenix, :json_library, Jason

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{config_env()}.exs"

# Sample configuration:
#
#     config :logger, :console,
#       level: :info,
#       format: "$date $time [$level] $metadata$message\n",
#       metadata: [:user_id]
#
