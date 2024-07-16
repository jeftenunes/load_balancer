defmodule LoadBalancer.Handler do
  alias LoadBalancer.{Conv, Parser, ServerStore}

  def handle(request) do
    request
    |> Parser.parse()
    |> forward_request()
  end

  defp forward_request(%Conv{} = request) do
    server = ServerStore.get_server()

    {:ok, finch_response} =
      Finch.build(
        request.method,
        "#{server}#{request.path}#{maybe_retrieve_qry_params(request.params)}"
      )
      |> Finch.request(LoadBalancer.Finch)

    parse_response(finch_response)
  end

  defp parse_response(finch_response) do
    """
    HTTP/1.1 #{finch_response.status} #{Parser.get_status_message(finch_response.status)}\r
    Content-Type: text/plain\r
    Content-Length: #{byte_size(finch_response.body)}\r
    \r
    #{finch_response.body}
    """
  end

  defp maybe_retrieve_qry_params("" = _qry_params), do: ""
  defp maybe_retrieve_qry_params(qry_params), do: "?#{qry_params}"
end
