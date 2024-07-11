defmodule LoadBalancer.Conv do
  defstruct method: "", path: "", status_code: nil, headers: %{}, params: %{}
end
