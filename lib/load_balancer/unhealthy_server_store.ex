defmodule LoadBalancer.UnhealthyServerStore do
  use Agent

  def start_link(_opts) do
    Agent.start_link(fn -> [] end, name: __MODULE__)
  end

  def flag_unhealthy_server(server) do
    Agent.update(__MODULE__, fn unhealthy_servers -> [server | unhealthy_servers] end)
  end

  def maybe_flag_healthy_server(server) do
    Agent.update(__MODULE__, fn unhealthy_servers ->
      if unhealthy_servers !== nil && Enum.member?(unhealthy_servers, server) do
        List.delete(unhealthy_servers, server)
      end
    end)
  end

  def is_server_flagged_unhealthy(server) do
    Agent.get(__MODULE__, fn unhealthy_server_list ->
      unhealthy_server_list !== nil && Enum.member?(unhealthy_server_list, server)
    end)
  end
end
