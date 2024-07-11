defmodule LoadBalancer.HttpServer do
  alias LoadBalancer.Handler

  use GenServer

  require Logger

  defstruct [:listen_socket]

  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts)
  end

  @impl true
  def init(opts) do
    port = Keyword.fetch!(opts, :port)

    listen_opts = [
      packet: :raw,
      mode: :binary,
      active: false,
      reuseaddr: true,
      exit_on_close: false
    ]

    case :gen_tcp.listen(port, listen_opts) do
      {:ok, sock} ->
        Logger.info("Listening on port #{port}")

        state = %__MODULE__{listen_socket: sock}
        {:ok, state, {:continue, :accept}}

      {:error, reason} ->
        {:stop, reason}
    end
  end

  @impl true
  def handle_continue(:accept, %__MODULE__{listen_socket: lsock} = state) do
    case :gen_tcp.accept(lsock) do
      {:ok, client_socket} ->
        Logger.info("⚡️  Connection accepted!\n")
        spawn(fn -> recv(client_socket) end)

        {:noreply, state, {:continue, :accept}}

      {:error, reason} ->
        {:stop, reason}
    end
  end

  def recv(client_socket) do
    case :gen_tcp.recv(client_socket, 0) do
      {:ok, data} ->
        Handler.handle(data)
        |> write_response(client_socket)

      {:error, :closed} ->
        :ok
    end
  end

  def write_response(response, client_socket) do
    :ok = :gen_tcp.send(client_socket, response)

    Logger.info("⬅️  Sent response:\n")
    Logger.info(response)

    # Closes the client socket, ending the connection.
    # Does not close the listen socket!
    :gen_tcp.close(client_socket)
  end
end
