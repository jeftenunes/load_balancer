defmodule LoadBalancer.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    port = String.to_integer(System.get_env("PORT") || "4000")

    children = [
      {LoadBalancer.HttpServer, port: port},
      {Finch, name: LoadBalancer.Finch}
      # Starts a worker by calling: LoadBalancer.Worker.start_link(arg)
      # {LoadBalancer.Worker, arg}
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: LoadBalancer.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
