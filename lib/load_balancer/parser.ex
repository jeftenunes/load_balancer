defmodule LoadBalancer.Conv do
  defstruct method: "", path: "", status_code: nil, headers: %{}, params: %{}
end

defmodule LoadBalancer.Parser do
  alias LoadBalancer.Conv

  @status_codes %{
    100 => "Continue",
    101 => "Switching Protocols",
    200 => "OK",
    201 => "Created",
    202 => "Accepted",
    203 => "Non-Authoritative Information",
    204 => "No Content",
    205 => "Reset Content",
    206 => "Partial Content",
    300 => "Multiple Choices",
    301 => "Moved Permanently",
    302 => "Found",
    303 => "See Other",
    304 => "Not Modified",
    305 => "Use Proxy",
    307 => "Temporary Redirect",
    400 => "Bad Request",
    401 => "Unauthorized",
    402 => "Payment Required",
    403 => "Forbidden",
    404 => "Not Found",
    405 => "Method Not Allowed",
    406 => "Not Acceptable",
    407 => "Proxy Authentication Required",
    408 => "Request Timeout",
    409 => "Conflict",
    410 => "Gone",
    411 => "Length Required",
    412 => "Precondition Failed",
    413 => "Payload Too Large",
    414 => "URI Too Long",
    415 => "Unsupported Media Type",
    416 => "Range Not Satisfiable",
    417 => "Expectation Failed",
    500 => "Internal Server Error",
    501 => "Not Implemented",
    502 => "Bad Gateway",
    503 => "Service Unavailable",
    504 => "Gateway Timeout",
    505 => "HTTP Version Not Supported"
  }

  def parse(req) do
    [top, params_str] = String.split(req, "\r\n\r\n")

    [req_line | header_lines] = String.split(top, "\r\n")
    [method, path, _] = req_line |> String.trim() |> String.split(" ")

    parsed_headers = parse_headers(header_lines, %{})

    %Conv{
      path: path,
      params: params_str,
      headers: parsed_headers,
      method: parse_method(method)
    }
  end

  def get_status_message(status_code),
    do: Map.get(@status_codes, status_code, "Unknown Status Code")

  defp parse_headers([], acc), do: acc

  defp parse_headers([curr | others], acc) do
    [name, value] = curr |> String.split(": ")
    parse_headers(others, Map.put(acc, name, value))
  end

  defp parse_method("GET"), do: :get
  defp parse_method("PUT"), do: :put
  defp parse_method("POST"), do: :post
end
