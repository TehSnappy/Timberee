defmodule Timberee.UsageState do
  use GenServer
  require Logger

  @topic "usage:state"

  # Client API

  def subscribe do
    Phoenix.PubSub.subscribe(Timberee.PubSub, @topic)
  end

  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  def get_state do
    GenServer.call(__MODULE__, :get_state)
  end

  def set_max_usage(value) when is_integer(value) and value >= 0 and value <= 100 do
    GenServer.cast(__MODULE__, {:set_max_usage, value})
  end

  def set_display_timeout(seconds)
      when is_integer(seconds) and seconds >= 0 and seconds <= 3600 do
    GenServer.cast(__MODULE__, {:set_display_timeout, seconds})
  end

  def touch do
    GenServer.cast(__MODULE__, :touch)
  end

  # Server Callbacks

  @impl true
  def init(_opts) do
    {:ok, default_state()}
  end

  @impl true
  def handle_call(:get_state, _from, state) do
    {:reply, state, state}
  end

  @impl true
  def handle_cast({:set_max_usage, value}, state) do
    set_and_broadcast(%{state | max_usage: value, last_action: DateTime.utc_now()})
  end

  @impl true
  def handle_cast({:set_display_timeout, seconds}, state) do
    set_and_broadcast(%{state | display_timeout: seconds, last_action: DateTime.utc_now()})
  end

  @impl true
  def handle_cast(:touch, state) do
    set_and_broadcast(%{state | last_action: DateTime.utc_now()})
  end

  # Private Functions

  defp set_and_broadcast(state) do
    broadcast_change(state)
    Logger.info("UsageState updated: #{inspect(state)}")
    {:noreply, state}
  end

  defp broadcast_change(state) do
    Phoenix.PubSub.broadcast(Timberee.PubSub, @topic, {:state_changed, state})
  end

  defp default_state do
    %{
      max_usage: 100,
      display_timeout: 3000,
      last_action: nil
    }
  end
end
