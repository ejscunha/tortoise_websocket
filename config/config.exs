use Mix.Config

if Mix.env() == :test do
  config :logger, level: :error
end
