defmodule VkApi do
  require HTTPoison
  require Jason

  @token Application.fetch_env!(:vel, :token)
  @v Application.fetch_env!(:vel, :v)

  def invoke(method, args) do
    method_url = "https://api.vk.com/method/" <> method

    args =
      args
      |> Map.put(:v, @v)
      |> Map.put(:access_token, @token)
      |> URI.encode_query()

    case HTTPoison.post(method_url, args, %{"Content-Type" => "application/x-www-form-urlencoded"}) do
      {:ok, %HTTPoison.Response{body: body}} -> body |> Jason.decode()
      {:error, resp} -> {:error, resp}
    end
  end

  defmacro gen(method, value) do
    quote do
      def unquote(method)(params) do
        VkApi.invoke(unquote(value), params)
      end
    end
  end
end
