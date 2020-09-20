defmodule FsetWeb.Presence do
  use Phoenix.Presence,
    otp_app: :fset,
    pubsub_server: Fset.PubSub
end
