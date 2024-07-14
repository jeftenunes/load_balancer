defmodule LoadBalancer.HealthCheck do
  use Task

  require Logger

  @servers Application.compile_env(:load_balancer, :servers)
  @health_check_endpoint Application.compile_env(:load_balancer, :health_check_endpoint)
  @health_check_interval Application.compile_env(:load_balancer, :health_check_interval_in_seconds) * 1000

  def start_link(_opts) do
    Task.start_link(fn -> schedule_health_check() end)
  end

  defp schedule_health_check() do
    Logger.info("Starting health check on #{@health_check_endpoint}")
    Enum.each(@servers, fn server -> spawn(fn -> execute_check(server) end) end)
  end

  defp execute_check(server) do
    Process.sleep(@health_check_interval)
    case @health_check_endpoint do
      _endpoint -> make_health_check_request(server) |> is_server_healthy?(server)
      nil -> {:ok, :healthy, %{server: server}}
    end

    execute_check(server)
  end

  defp is_server_healthy?(health_check_response, server) do
    case health_check_response do
      %{status: 200} -> Logger.info("Server #{server} health status: healthy")
      _ -> Logger.warning("Server #{server} health status: unhealthy")
    end
  end

  defp make_health_check_request(server) do
    {_op_status, health_check_response} =
      :get
      |>Finch.build(
        "#{server}#{@health_check_endpoint}"
      )
      |> Finch.request(LoadBalancer.Finch)
    health_check_response
  end
end
