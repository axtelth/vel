defmodule Longpoll do
  require VkApi
  require HTTPoison
  require Jason

  VkApi.gen(:getlongpollserver, "messages.getLongPollServer")

  def start(parent) do
    %{"response" => lp_srv_info} = update_lp()
    %{"key" => key, "server" => server, "ts" => ts} = lp_srv_info
    {:ok, response} = get_event(server, key, ts)
    send(parent, {:ok, response})
    listen(response, lp_srv_info, ts, parent)
  end

  defp update_lp() do
    case getlongpollserver(%{}) do
      {:ok, lp_srv_info} -> lp_srv_info
      _ -> update_lp()
    end
  end

  defp get_event(server, key, ts) do
    case HTTPoison.post(
           "https://" <> server,
           URI.encode_query(%{act: "a_check", key: key, ts: ts, wait: 25, mode: 2, version: 2}),
           %{"Content-Type" => "application/x-www-form-urlencoded"}
         ) do
      {:ok, %HTTPoison.Response{body: body}} -> body |> Jason.decode()
      _ -> get_event(server, key, ts)
    end
  end

  defp listen(response, lp_srv_info, ts, parent) do
    [response, lp_srv_info, ts] =
      case response["failed"] do
        x when x in [2, 3] ->
          %{"response" => lp_srv_info} = update_lp()
          %{"key" => key, "server" => server, "ts" => _} = lp_srv_info
          {:ok, response} = get_event(server, key, ts)
          send(parent, {:ok, response})
          [response, lp_srv_info, ts]

        _ ->
          server = lp_srv_info["server"]
          key = lp_srv_info["key"]
          ts = response["ts"]
          {:ok, response} = get_event(server, key, ts)
          send(parent, {:ok, response})
          [response, lp_srv_info, ts]
      end

    listen(response, lp_srv_info, ts, parent)
  end
end
