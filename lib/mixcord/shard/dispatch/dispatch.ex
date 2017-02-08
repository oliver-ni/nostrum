defmodule Mixcord.Shard.Dispatch do
  @moduledoc """
  Handles events from Discord's WS connection.

  All events received are handled in their own task. Any handlers you define will
  be run synchronously after the lib handles the event.

  To define your own event define a function like `handle_event/2`.
  The first parameter is a `tuple` containing the event type as an `atom` and the
  payload of the event as a `map`. The second parameter is the current `state` of the shard
  on which the event was received.

  ## Example
  ```elixir
  import Mixcord.Api, only: [create_message: 2]

  def handle_event({:MESSAGE_CREATE, message}, _state) do
    case message.content do
      "PONG" ->
        create_message(message.channel_id, "PING")
      "PING" ->
        create_message(message.channel_id, "PONG")
      _ ->
        create_message(message.channel_id, "I copy and pasted this code")
    end
  end
  ```
  """

  alias Mixcord.Cache.{Channel, Guild, User}
  alias Mixcord.Util
  require Logger

  @large_threshold 250

  def handle(payload, state) do
    Logger.debug payload.t
    payload = Util.safe_atom_map(payload)
    handle_event({payload.t, payload.d}, state)
  end

  def handle_event({:CHANNEL_CREATE, p}, _state), do: Channel.create(p)

  def handle_event({:CHANNEL_DELETE, p}, _state), do: Channel.delete(p)

  def handle_event({:CHANNEL_UPDATE, p}, _state), do: Channel.update(p)

  def handle_event({:CHANNEL_PINS_ACK, p}, _state), do: p

  def handle_event({:CHANNEL_PINS_UPDATE, p}, _state), do: p

  def handle_event({:GUILD_BAN_ADD, p}, _state), do: p

  def handle_event({:BUILD_BAN_REMOVE, p}, _state), do: p

  def handle_event({:GUILD_CREATE, p}, state) do
    if p.member_count < @large_threshold do
      Guild.create(p)
    else
      Guild.create(p, state.shard_pid)
    end
    p
  end

  def handle_event({:GUILD_UPDATE, p}, _state), do: Guild.update(p)

  def handle_event({:GUILD_DELETE, p}, _state), do: Guild.delete(p.id)

  def handle_event({:GUILD_EMOJIS_UPDATE, p}, _state), do: Guild.emoji_update(p.guild_id, p.emojis)

  def handle_event({:GUILD_INTEGRATIONS_UPDATE, p}, _state), do: p

  def handle_event({:GUILD_MEMBER_ADD, p}, _state), do: Guild.member_add(p.guild_id, p)

  def handle_event({:GUILD_MEMBERS_CHUNK, p}, _state) do
    p.members
      |> Enum.each(fn member -> Guild.member_add(p.guild_id, member) end)
    p
  end

  def handle_event({:GUILD_MEMBER_REMOVE, p}, _state), do: Guild.member_remove(p.guild_id, p.user)

  # What is this even??
  def handle_event({:GUILD_MEMBER_UPDATE, p}, _state), do: Guild.member_update(p.guild_id, p.user, p.nick, p.roles)

  def handle_event({:GUILD_ROLE_CREATE, p}, _state), do: Guild.role_create(p.guild_id, p.role)

  def handle_event({:GUILD_ROLE_DELETE, p}, _state), do: Guild.role_delete(p.guild_id, p.role_id)

  def handle_event({:GUILD_ROLE_UPDATE, p}, _state), do: Guild.role_update(p.guild_id, p.role)

  def handle_event({:MESSAGE_CREATE, p}, _state), do: p

  def handle_event({:MESSAGE_DELETE, p}, _state), do: p

  def handle_event({:MESSAGE_DELETE_BULK, p}, _state), do: p

  def handle_event({:MESSAGE_UPDATE, p}, _state), do: p

  def handle_event({:PRESENCE_UPDATE, p}, _state), do: p

  def handle_event({:READY, p}, _state) do
    p.private_channels
      |> Enum.each(fn dm_channel -> Channel.create(dm_channel) end)
    p.guilds
      |> Enum.each(fn guild -> Guild.create(guild) end)
    p
  end

  def handle_event({:RESUMED, p}, _state), do: p

  def handle_event({:TYPING_START, p}, _state), do: p

  def handle_event({:USER_SETTINGS_UPDATE, p}, _state), do: p

  def handle_event({:USER_UPDATE, p}, _state), do: User.update(p)

  def handle_event({:VOICE_STATE_UPDATE, p}, _state), do: p

  def handle_event({:VOICE_SERVER_UPDATE, p}, _state), do: p

  def handle_event({event, _p}, _state), do: Logger.warn "UNHANDLED GATEWAY DISPATCH EVENT TYPE: #{event}"

end