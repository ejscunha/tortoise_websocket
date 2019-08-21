defmodule Tortoise.Support.WebsocketFrameParser do
  use Bitwise

  def parse(frame) do
    <<_::8, mask::1, _::7, rest::binary>> = frame

    if mask == 1 do
      <<key::32, data::binary>> = rest
      unmask(key, data)
    else
      rest
    end
  end

  defp unmask(key, data) do
    unmask(key, data, <<>>)
  end

  defp unmask(key, <<data::32, rest::binary>>, acc) do
    unmask(key, rest, <<acc::binary, data ^^^ key::32>>)
  end

  defp unmask(key, <<data::24>>, acc) do
    <<key::24, _::8>> = <<key::32>>

    unmask(key, <<>>, <<acc::binary, data ^^^ key::24>>)
  end

  defp unmask(key, <<data::16>>, acc) do
    <<key::16, _::16>> = <<key::32>>

    unmask(key, <<>>, <<acc::binary, data ^^^ key::16>>)
  end

  defp unmask(key, <<data::8>>, acc) do
    <<key::8, _::24>> = <<key::32>>

    unmask(key, <<>>, <<acc::binary, data ^^^ key::8>>)
  end

  defp unmask(_, <<>>, acc) do
    acc
  end
end
