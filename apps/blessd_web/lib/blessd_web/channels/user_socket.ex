defmodule BlessdWeb.UserSocket do
  use Phoenix.Socket

  alias Blessd.Auth

  ## Channels
  channel("attendance:*", BlessdWeb.AttendanceChannel)

  ## Transports
  transport(:websocket, Phoenix.Transports.WebSocket)

  def connect(%{"token" => token}, socket) do
    case Phoenix.Token.verify(socket, "user socket", token, max_age: 1_209_600) do
      {:ok, {user_id, church_id}} ->
        {:ok, assign(socket, :current_user, Auth.get_user!(user_id, church_id))}

      {:error, _reason} ->
        :error
    end
  end

  def id(_socket), do: nil
end
