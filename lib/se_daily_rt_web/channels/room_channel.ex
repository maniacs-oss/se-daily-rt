defmodule SEDailyRTWeb.RoomChannel do
  use SEDailyRTWeb, :channel
  alias SEDailyRTWeb.Presence
  alias SEDailyRT.Accounts
  

  def join("room:lobby", payload, socket) do
    case create_or_load_user(payload) do
      %{username: username} -> 
        send(self(), :after_join)
        {:ok, assign(socket, :username, username)}
      _ -> 
        {:error, %{reason: "unauthorized"}}
    end
  end

  # Channels can be used in a request/response fashion
  # by sending replies to requests from the client
  def handle_in("ping", payload, socket) do
    {:reply, {:ok, payload}, socket}
  end

  # Hanle user joins and leaves using Presence
  def handle_info(:after_join, socket) do
    push socket, "presence_state", Presence.list(socket)
    {:ok, _} = Presence.track(socket, socket.assigns.username, %{
      online_at: inspect(System.system_time(:seconds))
    })
    {:noreply, socket}
  end

  def handle_in("create_chat_message", %{"text" => message}, socket) do
    %{assigns: %{username: username}} = socket

    # Save to database
    
    # Broadcast event to clients
    broadcast socket, "new_message", %{"username" => username, "text" => message}
    {:noreply, socket}
  end
  
  # Create or load the user by the username
  defp create_or_load_user(%{"username" => username}) do
    case Accounts.get_user_by_username(username) do
      nil -> Accounts.create_user(%{"username" => username})
      user -> user
    end
  end
end
