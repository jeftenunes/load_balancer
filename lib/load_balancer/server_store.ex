defmodule LoadBalancer.ServerStore do
  use Agent

  alias LoadBalancer.UnhealthyServerStore

  @servers Application.compile_env(:load_balancer, :servers)

  def start_link(_opts) do
    Agent.start_link(fn -> {@servers, 0} end, name: __MODULE__)
  end

  def get_server() do
    Agent.get_and_update(__MODULE__, fn {servers, idx} ->
      retrieve_next_srv(servers, idx)
    end)
  end

  def retrieve_next_srv(servers, idx) do
    next = rem(idx + 1, length(servers))

    if !UnhealthyServerStore.is_server_flagged_unhealthy(Enum.at(servers, idx)) do
      {Enum.at(servers, idx), {servers, next}}
    else
      retrieve_next_srv(servers, next)
    end
  end
end
