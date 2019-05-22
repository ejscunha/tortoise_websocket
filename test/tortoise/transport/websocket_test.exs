defmodule Tortoise.Transport.WebsocketTest do
  use ExUnit.Case, async: true
  alias Tortoise.Support.ScriptedMqttServer
  alias Tortoise.Connection
  alias Tortoise.Package

  setup context do
    client_id = Atom.to_string(context.test)

    {:ok, pid} = ScriptedMqttServer.start_link()

    {:ok, %{client_id: client_id, scripted_mqtt_server: pid}}
  end

  describe "successful connect" do
    test "without present state", context do
      client_id = context.client_id

      connect = %Package.Connect{client_id: client_id, clean_session: true}
      expected_connack = %Package.Connack{status: :accepted, session_present: false}

      script = [{:receive, connect}, {:send, expected_connack}]

      {:ok, {ip, port}} = ScriptedMqttServer.enact(context.scripted_mqtt_server, script)

      opts = [
        client_id: client_id,
        server: {Tortoise.Transport.Websocket, [host: ip, port: port]},
        handler: {Tortoise.Handler.Default, []}
      ]

      assert {:ok, _pid} = Connection.start_link(opts)
      assert_receive {ScriptedMqttServer, {:received, ^connect}}
      assert_receive {ScriptedMqttServer, :completed}
    end

    test "reconnect with present state", context do
      client_id = context.client_id

      connect = %Package.Connect{client_id: client_id, clean_session: true}
      reconnect = %Package.Connect{connect | clean_session: false}

      script = [
        {:receive, connect},
        {:send, %Package.Connack{status: :accepted, session_present: false}},
        :disconnect,
        {:receive, reconnect},
        {:send, %Package.Connack{status: :accepted, session_present: true}}
      ]

      {:ok, {ip, port}} = ScriptedMqttServer.enact(context.scripted_mqtt_server, script)

      opts = [
        client_id: client_id,
        server: {Tortoise.Transport.Websocket, [host: ip, port: port]},
        handler: {Tortoise.Handler.Default, []}
      ]

      assert {:ok, _pid} = Connection.start_link(opts)
      assert_receive {ScriptedMqttServer, {:received, ^connect}}
      assert_receive {ScriptedMqttServer, {:received, ^reconnect}}
      assert_receive {ScriptedMqttServer, :completed}
    end
  end

  describe "unsuccessful connect" do
    test "unacceptable protocol version", context do
      Process.flag(:trap_exit, true)
      client_id = context.client_id

      connect = %Package.Connect{client_id: client_id}

      script = [
        {:receive, connect},
        {:send, %Package.Connack{status: {:refused, :unacceptable_protocol_version}}}
      ]

      true = Process.unlink(context.scripted_mqtt_server)
      {:ok, {ip, port}} = ScriptedMqttServer.enact(context.scripted_mqtt_server, script)

      opts = [
        client_id: client_id,
        server: {Tortoise.Transport.Websocket, [host: ip, port: port]},
        handler: {Tortoise.Handler.Default, []}
      ]

      assert {:ok, pid} = Connection.start_link(opts)

      assert_receive {ScriptedMqttServer, {:received, ^connect}}
      assert_receive {ScriptedMqttServer, :completed}
      assert_receive {:EXIT, ^pid, {:connection_failed, :unacceptable_protocol_version}}
    end

    test "identifier rejected", context do
      Process.flag(:trap_exit, true)
      client_id = context.client_id

      connect = %Package.Connect{client_id: client_id}
      expected_connack = %Package.Connack{status: {:refused, :identifier_rejected}}

      script = [{:receive, connect}, {:send, expected_connack}]
      {:ok, {ip, port}} = ScriptedMqttServer.enact(context.scripted_mqtt_server, script)

      opts = [
        client_id: client_id,
        server: {Tortoise.Transport.Websocket, [host: ip, port: port]},
        handler: {Tortoise.Handler.Default, []}
      ]

      assert {:ok, pid} = Connection.start_link(opts)
      assert_receive {ScriptedMqttServer, {:received, ^connect}}
      assert_receive {ScriptedMqttServer, :completed}
      assert_receive {:EXIT, ^pid, {:connection_failed, :identifier_rejected}}
    end

    test "server unavailable", context do
      Process.flag(:trap_exit, true)
      client_id = context.client_id

      connect = %Package.Connect{client_id: client_id}
      expected_connack = %Package.Connack{status: {:refused, :server_unavailable}}

      script = [{:receive, connect}, {:send, expected_connack}]
      {:ok, {ip, port}} = ScriptedMqttServer.enact(context.scripted_mqtt_server, script)

      opts = [
        client_id: client_id,
        server: {Tortoise.Transport.Websocket, [host: ip, port: port]},
        handler: {Tortoise.Handler.Default, []}
      ]

      assert {:ok, pid} = Connection.start_link(opts)
      assert_receive {ScriptedMqttServer, {:received, ^connect}}
      assert_receive {ScriptedMqttServer, :completed}
      assert_receive {:EXIT, ^pid, {:connection_failed, :server_unavailable}}
    end

    test "bad user name or password", context do
      Process.flag(:trap_exit, true)
      client_id = context.client_id

      connect = %Package.Connect{client_id: client_id}
      expected_connack = %Package.Connack{status: {:refused, :bad_user_name_or_password}}

      script = [{:receive, connect}, {:send, expected_connack}]
      {:ok, {ip, port}} = ScriptedMqttServer.enact(context.scripted_mqtt_server, script)

      opts = [
        client_id: client_id,
        server: {Tortoise.Transport.Websocket, [host: ip, port: port]},
        handler: {Tortoise.Handler.Default, []}
      ]

      assert {:ok, pid} = Connection.start_link(opts)
      assert_receive {ScriptedMqttServer, {:received, ^connect}}
      assert_receive {ScriptedMqttServer, :completed}
      assert_receive {:EXIT, ^pid, {:connection_failed, :bad_user_name_or_password}}
    end

    test "not authorized", context do
      Process.flag(:trap_exit, true)
      client_id = context.client_id

      connect = %Package.Connect{client_id: client_id}
      expected_connack = %Package.Connack{status: {:refused, :not_authorized}}

      script = [{:receive, connect}, {:send, expected_connack}]
      {:ok, {ip, port}} = ScriptedMqttServer.enact(context.scripted_mqtt_server, script)

      opts = [
        client_id: client_id,
        server: {Tortoise.Transport.Websocket, [host: ip, port: port]},
        handler: {Tortoise.Handler.Default, []}
      ]

      assert {:ok, pid} = Connection.start_link(opts)
      assert_receive {ScriptedMqttServer, {:received, ^connect}}
      assert_receive {ScriptedMqttServer, :completed}

      assert_receive {:EXIT, ^pid, {:connection_failed, :not_authorized}}
    end
  end

  describe "subscriptions" do
    test "successful subscription", context do
      client_id = context.client_id

      connect = %Package.Connect{client_id: client_id, clean_session: true}
      subscription_foo = Enum.into([{"foo", 0}], %Package.Subscribe{identifier: 1})
      subscription_bar = Enum.into([{"bar", 1}], %Package.Subscribe{identifier: 2})
      subscription_baz = Enum.into([{"baz", 2}], %Package.Subscribe{identifier: 3})

      script = [
        {:receive, connect},
        {:send, %Package.Connack{status: :accepted, session_present: false}},
        # subscribe to foo with qos 0
        {:receive, subscription_foo},
        {:send, %Package.Suback{identifier: 1, acks: [{:ok, 0}]}},
        # subscribe to bar with qos 0
        {:receive, subscription_bar},
        {:send, %Package.Suback{identifier: 2, acks: [{:ok, 1}]}},
        {:receive, subscription_baz},
        {:send, %Package.Suback{identifier: 3, acks: [{:ok, 2}]}}
      ]

      {:ok, {ip, port}} = ScriptedMqttServer.enact(context.scripted_mqtt_server, script)

      opts = [
        client_id: client_id,
        server: {Tortoise.Transport.Websocket, [host: ip, port: port]},
        handler: {Tortoise.Handler.Default, []}
      ]

      # connection
      assert {:ok, _pid} = Connection.start_link(opts)
      assert_receive {ScriptedMqttServer, {:received, ^connect}}

      # subscribe to a foo
      :ok = Tortoise.Connection.subscribe_sync(client_id, {"foo", 0}, identifier: 1)
      assert_receive {ScriptedMqttServer, {:received, ^subscription_foo}}
      assert Enum.member?(Tortoise.Connection.subscriptions(client_id), {"foo", 0})

      # subscribe to a bar
      assert {:ok, ref} = Tortoise.Connection.subscribe(client_id, {"bar", 1}, identifier: 2)
      assert_receive {{Tortoise, ^client_id}, ^ref, :ok}
      assert_receive {ScriptedMqttServer, {:received, ^subscription_bar}}

      # subscribe to a baz
      assert {:ok, ref} = Tortoise.Connection.subscribe(client_id, "baz", qos: 2, identifier: 3)
      assert_receive {{Tortoise, ^client_id}, ^ref, :ok}
      assert_receive {ScriptedMqttServer, {:received, ^subscription_baz}}

      # foo, bar, and baz should now be in the subscription list
      subscriptions = Tortoise.Connection.subscriptions(client_id)
      assert Enum.member?(subscriptions, {"foo", 0})
      assert Enum.member?(subscriptions, {"bar", 1})
      assert Enum.member?(subscriptions, {"baz", 2})

      # done
      assert_receive {ScriptedMqttServer, :completed}
    end

    test "successful unsubscribe", context do
      client_id = context.client_id

      connect = %Package.Connect{client_id: client_id, clean_session: true}
      unsubscribe_foo = %Package.Unsubscribe{identifier: 2, topics: ["foo"]}
      unsubscribe_bar = %Package.Unsubscribe{identifier: 3, topics: ["bar"]}

      script = [
        {:receive, connect},
        {:send, %Package.Connack{status: :accepted, session_present: false}},
        {:receive, %Package.Subscribe{topics: [{"foo", 0}, {"bar", 2}], identifier: 1}},
        {:send, %Package.Suback{acks: [ok: 0, ok: 2], identifier: 1}},
        # unsubscribe foo
        {:receive, unsubscribe_foo},
        {:send, %Package.Unsuback{identifier: 2}},
        # unsubscribe bar
        {:receive, unsubscribe_bar},
        {:send, %Package.Unsuback{identifier: 3}}
      ]

      {:ok, {ip, port}} = ScriptedMqttServer.enact(context.scripted_mqtt_server, script)

      subscribe = %Package.Subscribe{topics: [{"foo", 0}, {"bar", 2}], identifier: 1}

      opts = [
        client_id: client_id,
        server: {Tortoise.Transport.Websocket, [host: ip, port: port]},
        handler: {Tortoise.Handler.Default, []},
        subscriptions: subscribe
      ]

      assert {:ok, _pid} = Connection.start_link(opts)
      assert_receive {ScriptedMqttServer, {:received, ^connect}}

      assert_receive {ScriptedMqttServer, {:received, ^subscribe}}

      # now let us try to unsubscribe from foo
      :ok = Tortoise.Connection.unsubscribe_sync(client_id, "foo", identifier: 2)
      assert_receive {ScriptedMqttServer, {:received, ^unsubscribe_foo}}

      assert %Package.Subscribe{topics: [{"bar", 2}]} =
               Tortoise.Connection.subscriptions(client_id)

      # and unsubscribe from bar
      assert {:ok, ref} = Tortoise.Connection.unsubscribe(client_id, "bar", identifier: 3)
      assert_receive {{Tortoise, ^client_id}, ^ref, :ok}
      assert_receive {ScriptedMqttServer, {:received, ^unsubscribe_bar}}
      assert %Package.Subscribe{topics: []} = Tortoise.Connection.subscriptions(client_id)

      assert_receive {ScriptedMqttServer, :completed}
    end
  end

  describe "socket subscription" do
    test "receive a socket from a connection", context do
      client_id = context.client_id

      connect = %Package.Connect{client_id: client_id, clean_session: true}
      expected_connack = %Package.Connack{status: :accepted, session_present: false}

      script = [{:receive, connect}, {:send, expected_connack}]

      {:ok, {ip, port}} = ScriptedMqttServer.enact(context.scripted_mqtt_server, script)

      opts = [
        client_id: client_id,
        server: {Tortoise.Transport.Websocket, [host: ip, port: port]},
        handler: {Tortoise.Handler.Default, []}
      ]

      assert {:ok, _pid} = Connection.start_link(opts)
      assert_receive {ScriptedMqttServer, {:received, ^connect}}

      assert {:ok, {Tortoise.Transport.Websocket, _socket}} =
               Connection.connection(client_id, timeout: 500)

      assert_receive {ScriptedMqttServer, :completed}
    end

    test "timeout on a socket from a connection", context do
      client_id = context.client_id

      connect = %Package.Connect{client_id: client_id, clean_session: true}

      script = [{:receive, connect}, :pause]

      {:ok, {ip, port}} = ScriptedMqttServer.enact(context.scripted_mqtt_server, script)

      opts = [
        client_id: client_id,
        server: {Tortoise.Transport.Websocket, [host: ip, port: port]},
        handler: {Tortoise.Handler.Default, []}
      ]

      assert {:ok, _pid} = Connection.start_link(opts)
      assert_receive {ScriptedMqttServer, {:received, ^connect}}
      assert_receive {ScriptedMqttServer, :paused}

      assert {:error, :timeout} = Connection.connection(client_id, timeout: 5)

      send(context.scripted_mqtt_server, :continue)
      assert_receive {ScriptedMqttServer, :completed}
    end
  end

  describe "life-cycle" do
    test "connect and cleanly disconnect", context do
      Process.flag(:trap_exit, true)
      client_id = context.client_id

      connect = %Package.Connect{client_id: client_id}
      expected_connack = %Package.Connack{status: :accepted, session_present: false}
      disconnect = %Package.Disconnect{}

      script = [{:receive, connect}, {:send, expected_connack}, {:receive, disconnect}]

      {:ok, {ip, port}} = ScriptedMqttServer.enact(context.scripted_mqtt_server, script)

      opts = [
        client_id: client_id,
        server: {Tortoise.Transport.Websocket, [host: ip, port: port]},
        handler: {Tortoise.Handler.Default, []}
      ]

      assert {:ok, pid} = Connection.start_link(opts)
      assert_receive {ScriptedMqttServer, {:received, ^connect}}

      assert :ok = Tortoise.Connection.disconnect(client_id)
      assert_receive {ScriptedMqttServer, {:received, ^disconnect}}
      assert_receive {:EXIT, ^pid, :shutdown}

      assert_receive {ScriptedMqttServer, :completed}
    end
  end
end
