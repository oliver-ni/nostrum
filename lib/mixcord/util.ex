defmodule Mixcord.Util do
  @moduledoc false

  alias Mixcord.Api.Ratelimiter
  alias Mixcord.Constants

  def empty_cache do
    Mixcord.Cache.Supervisor.empty_cache
  end

  def now do
    DateTime.utc_now
      |> DateTime.to_unix(:milliseconds)
  end

  def num_shards do
    Application.get_env(:mixcord, :num_shards)
  end

  def gateway do
    case :ets.lookup(:gateway_url, "url") do
      [] -> get_new_gateway_url
      [{"url", url}] -> url
    end
  end

  defp get_new_gateway_url do
    case Ratelimiter.request(:get, Constants.gateway, "") do
      {:error, status_code: status_code, message: message} ->
        raise(Mixcord.Error.ApiError, status_code: status_code, message: message)
      {:ok, body} ->

        url = body["url"] <> "?encoding=etf&v=6"
          |> to_charlist
        :ets.insert(:gateway_url, {"url", url})

        url
    end
  end

end