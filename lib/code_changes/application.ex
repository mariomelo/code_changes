defmodule CodeChanges.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      CodeChangesWeb.Telemetry,
      {DNSCluster, query: Application.get_env(:code_changes, :dns_cluster_query) || :ignore},
      {Phoenix.PubSub, name: CodeChanges.PubSub},
      # Start the Finch HTTP client for sending emails
      {Finch, name: CodeChanges.Finch},
      # Start a worker by calling: CodeChanges.Worker.start_link(arg)
      # {CodeChanges.Worker, arg},
      # Start to serve requests, typically the last entry
      CodeChangesWeb.Endpoint
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: CodeChanges.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    CodeChangesWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
