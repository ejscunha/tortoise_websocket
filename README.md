# TortoiseWebsocket

Tortoise Websocket transport, the websocket client is based on [gun](https://github.com/ninenines/gun).

## Installation

The package can be installed by adding `tortoise_websocket` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:tortoise, "~> 0.9"},
    {:tortoise_websocket, "~> 0.1.0"}
  ]
end
```

## Usage

To connect to a MQTT server using websockets you need to do the following:

```elixir
Tortoise.Supervisor.start_child(
    client_id: "my_client_id",
    handler: {Tortoise.Handler.Logger, []},
    server: {Tortoise.Transport.Websocket, host: 'localhost', port: 80},
    subscriptions: [{"foo/bar", 0}])
```

Besides `:host` and `:port` options you can set the following optional options:

* `:transport` - An atom with the transport protocol, either `:tcp` or `:tls`, defaults to `:tcp`
* `:path` - A string with the websocket server path, defaults to `"/"`
* `:headers` - A list of tuples with the HTTP headers to send to the server, defaults to `[]`
* `:active` - A boolean or atom to indicate if the client should send back any received data, it can be `true`, `false` and `:once`, defaults to `false`
* `:compress` - A boolean to indicate if the data should be compressed, defaults to `true`
