defmodule Vel do
  import VkApi
  require Longpoll

  gen(:messageSend, "messages.send")

  @spec main :: no_return
  def main do
    spawn(Longpoll, :start, [self()])
    handler()
  end

  @spec handler :: no_return
  defp handler do
    receive do
      {:ok, response} ->
        updates = response["updates"]

        unless updates == nil do
          Enum.each(updates, fn update ->
            Task.start(fn -> handle_event(update) end)
          end)
        end
    end

    handler()
  end

  defp handle_event([4, _msg_id, _flags, peer_id, _timestamp, text, meta]) do
    unless meta["title"] do
      handle_message(peer_id, text, meta["from"])
    end
  end

  defp handle_event(_), do: nil

  defp handle_message(peer_id, text, _sender) do
    case text |> String.downcase() do
      "мяу" ->
        %{
          peer_id: peer_id,
          message: "мур",
          random_id: Enum.random(0..999_999)
        }
        |> messageSend

      _ ->
        nil
    end
  end
end
