defmodule Timberee.Application do
  @moduledoc false

  use Application

  def start(_type, _args) do
    children = [
      TimbereeWeb.Telemetry,
      Timberee.TimberState,
      {DNSCluster, query: Application.get_env(:timberee, :dns_cluster_query) || :ignore},
      {Phoenix.PubSub, name: Timberee.PubSub},
      TimbereeWeb.Endpoint,
      TimbereeScenic
      # {Timberee.Display, restart: :transient}
    ]

    opts = [strategy: :one_for_one, name: Timberee.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  def config_change(changed, _new, removed) do
    TimbereeWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
