defmodule LoadBalancer.HealthCheck do
  use Task

  require Logger

  alias LoadBalancer.UnhealthyServerStore

  @servers Application.compile_env(:load_balancer, :servers)
  @health_check_endpoint Application.compile_env(:load_balancer, :health_check_endpoint)
  @health_check_interval Application.compile_env(
                           :load_balancer,
                           :health_check_interval_in_seconds
                         ) * 1000

  def start_link(_opts) do
    Task.start_link(fn -> if @health_check_endpoint != nil, do: schedule_health_check() end)
  end

  defp schedule_health_check() do
    Logger.info("Starting health check on #{@health_check_endpoint}")
    Enum.each(@servers, fn server -> spawn(fn -> execute_check(server) end) end)
  end

  defp execute_check(server) do
    Process.sleep(@health_check_interval)

    make_health_check_request(server) |> flag_server_healthy_status(server)

    execute_check(server)
  end

  defp flag_server_healthy_status(health_check_response, server) do
    case health_check_response do
      %{status: 200} ->
        UnhealthyServerStore.maybe_flag_healthy_server(server)
        Logger.info("Server #{server} health status: healthy")

      _ ->
        UnhealthyServerStore.flag_unhealthy_server(server)
        Logger.warning("Server #{server} health status: unhealthy")
    end
  end

  defp make_health_check_request(server) do
    {_op_status, health_check_response} =
      :get
      |> Finch.build("#{server}#{@health_check_endpoint}")
      |> Finch.request(LoadBalancer.Finch)

    health_check_response
  end
end
