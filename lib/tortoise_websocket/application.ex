defmodule TortoiseWebsocket.Application do
  @moduledoc false

  use Application

  def start(_type, _args) do
    children = [
      TortoiseWebsocket.Client.Supervisor
    ]

    opts = [strategy: :one_for_one, name: TortoiseWebsocket.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
