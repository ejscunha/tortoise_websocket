defmodule TortoiseWebsocket.ClientTest do
  use ExUnit.Case
  alias TortoiseWebsocket.Client
  alias TortoiseWebsocket.Support.WebsocketServer

  @host 'localhost'

  setup context do
    port = Enum.random(49152..65535)

    opts =
      context
      |> Map.get(:opts, [])
      |> Keyword.put(:port, port)

    {:ok, server_pid} = start_supervised({WebsocketServer, opts})
    {:ok, port: port, server_pid: server_pid}
  end

  test "#connect it connects to the server and returns {:ok, socket}", %{port: port} do
    assert {:ok, %Client.Socket{pid: pid}} = Client.connect(@host, port)
    assert is_pid(pid)
  end

  test "#connect if the server is not available in the given port it returns {:error, :econnrefused}",
       %{
         port: port
       } do
    assert {:error, :econnrefused} = Client.connect(@host, port - 1)
  end

  @tag opts: [delay: 2]
  test "#connect if the connection exceeds the timeout it returns {:error, :timeout}", %{
    port: port,
    opts: opts
  } do
    assert {:error, :timeout} = Client.connect(@host, port, [], opts[:delay] - 1)
  end

  test "#connect if the host can not be resolved it retuns {:error, :nxdomain}", %{
    port: port
  } do
    assert {:error, :nxdomain} = Client.connect('invalid', port)
  end

  test "#send it sends binary data to the websocket server and returns :ok", %{
    port: port,
    server_pid: server_pid
  } do
    data = "data"
    {:ok, socket} = Client.connect(@host, port)
    assert :ok = Client.send(socket, data)
    Process.sleep(10)
    assert WebsocketServer.received?(server_pid, data)
  end

  test "#recv it receives binary data with the provided length from the websocket server and returns {:ok, data}",
       %{
         port: port,
         server_pid: server_pid
       } do
    data = "data"
    {:ok, socket} = Client.connect(@host, port)
    WebsocketServer.send(server_pid, data)
    assert {:ok, ^data} = Client.recv(socket, byte_size(data))
  end

  test "#recv it returns binary data equivalent to the provided length in bytes",
       %{
         port: port,
         server_pid: server_pid
       } do
    data = "datadata"
    expected_received_data = "data"
    expected_received_data_length = byte_size(expected_received_data)
    {:ok, socket} = Client.connect(@host, port)
    WebsocketServer.send(server_pid, data)
    assert {:ok, ^expected_received_data} = Client.recv(socket, expected_received_data_length)
    assert {:ok, ^expected_received_data} = Client.recv(socket, expected_received_data_length)
  end

  test "#recv if the provided length is 0 it returns all data present in the server",
       %{
         port: port,
         server_pid: server_pid
       } do
    data = "data"
    {:ok, socket} = Client.connect(@host, port)
    WebsocketServer.send(server_pid, data)
    Process.sleep(10)
    assert {:ok, ^data} = Client.recv(socket, 0)
  end

  test "#recv if the provided timeout is exceeded it returns {:error, :timeout}", %{port: port} do
    {:ok, socket} = Client.connect(@host, port)
    assert {:error, :timeout} = Client.recv(socket, 1, 10)
  end

  test "#controlling_process it changes the owning process of the client and returns :ok", %{
    port: port,
    server_pid: server_pid
  } do
    {:ok, socket} = Client.connect(@host, port, active: true)
    test_pid = self()
    data = "data"

    new_owner =
      spawn(fn ->
        receive do
          msg -> send(test_pid, msg)
        end
      end)

    assert :ok = Client.controlling_process(socket, new_owner)
    WebsocketServer.send(server_pid, data)

    assert_receive({:websocket, ^socket, ^data})
  end

  test "#close it closes the connection to the server and stops the client and returns :ok", %{
    port: port
  } do
    {:ok, socket} = Client.connect(@host, port)
    assert :ok = Client.close(socket)
    assert {:error, :closed} = Client.send(socket, "data")
  end

  test "#set_active it defines the client active mode and returns :ok", %{
    port: port,
    server_pid: server_pid
  } do
    data = "data"
    {:ok, socket} = Client.connect(@host, port, active: false)

    assert :ok = Client.set_active(socket, true)
    WebsocketServer.send(server_pid, data)
    assert_receive({:websocket, ^socket, ^data})
    WebsocketServer.send(server_pid, data)
    assert_receive({:websocket, ^socket, ^data})

    assert :ok = Client.set_active(socket, false)
    WebsocketServer.send(server_pid, data)
    refute_receive({:websocket, ^socket, ^data}, 10)
    assert {:ok, ^data} = Client.recv(socket, 0)

    assert :ok = Client.set_active(socket, :once)
    WebsocketServer.send(server_pid, data)
    assert_receive({:websocket, ^socket, ^data})
    WebsocketServer.send(server_pid, data)
    refute_receive({:websocket, ^socket, ^data}, 10)
    assert {:ok, ^data} = Client.recv(socket, 0)
  end

  test "if server closes the connection, the client sends the message {:websocket_closed, socket} to the owner",
       %{port: port, server_pid: server_pid} do
    {:ok, socket} = Client.connect(@host, port, active: false)
    WebsocketServer.close(server_pid)
    assert_receive({:websocket_closed, ^socket})
  end
end
