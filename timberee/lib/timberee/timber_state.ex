defmodule Timberee.TimberState do
  @moduledoc """
  GenServer that manages the shared state for timber monitoring:
  - Water supply level (0-100%)
  - Time remaining (in seconds)
  - Season status (string)

  Broadcasts state changes via PubSub.
  """
  use GenServer
  require Logger

  @topic "timber:state"

  # Client API

  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @doc """
  Get the current state.
  Returns: %{water_level: float, time_remaining: integer, season: string}
  """
  def get_state do
    GenServer.call(__MODULE__, :get_state)
  end

  @doc """
  Update the water level (0-100%)
  """
  def update_water_level(level) when level >= 0 and level <= 100 do
    GenServer.cast(__MODULE__, {:update_water_level, level})
  end

  @doc """
  Update the time remaining (in seconds)
  """
  def update_time_remaining(seconds) when is_integer(seconds) and seconds >= 0 do
    GenServer.cast(__MODULE__, {:update_time_remaining, seconds})
  end

  @doc """
  Update the season status
  """
  def update_season(season) when is_binary(season) do
    GenServer.cast(__MODULE__, {:update_season, season})
  end

  def update_upcoming_season(upcoming_season) when is_binary(upcoming_season) do
    GenServer.cast(__MODULE__, {:update_upcoming_season, upcoming_season})
  end

  def update_reservoirs(name, fill_percent) when is_binary(name) and is_number(fill_percent) do
    GenServer.cast(__MODULE__, {:update_reservoirs, name, fill_percent})
  end

  def update_battery_level(level) when level >= 0 and level <= 100 do
    GenServer.cast(__MODULE__, {:update_battery_level, level})
  end

  def update_flow_level(status) do
    GenServer.cast(__MODULE__, {:update_flow_level, status})
  end

  @doc """
  Subscribe to state change notifications
  """
  def subscribe do
    Phoenix.PubSub.subscribe(Timberee.PubSub, @topic)
  end

  # Server Callbacks

  @impl true
  def init(_opts) do
    state = %{
      water_level: 50.0,
      time_remaining: 0,
      season: "temperate",
      upcoming_season: "drought",
      battery_level: 100,
      flow_level: 0,
      reservoirs: %{}
    }

    Logger.info("TimberState GenServer started with initial state: #{inspect(state)}")
    {:ok, state}
  end

  @impl true
  def handle_call(:get_state, _from, state) do
    {:reply, state, state}
  end

  @impl true
  def handle_cast({:update_reservoirs, name, fill_percent}, %{reservoirs: reservoirs} = state) do
    new_state = %{state | reservoirs: Map.put(reservoirs, name, fill_percent)}
    broadcast_change(new_state)
    {:noreply, new_state}
  end

  @impl true
  def handle_cast({:update_water_level, level}, state) do
    new_state = %{state | water_level: level}
    broadcast_change(new_state)
    {:noreply, new_state}
  end

  @impl true
  def handle_cast({:update_time_remaining, seconds}, state) do
    new_state = %{state | time_remaining: seconds}
    broadcast_change(new_state)
    {:noreply, new_state}
  end

  @impl true
  def handle_cast({:update_season, season}, state) do
    new_state = %{state | season: season}
    broadcast_change(new_state)
    {:noreply, new_state}
  end

  @impl true
  def handle_cast({:update_upcoming_season, upcoming_season}, state) do
    new_state = %{state | upcoming_season: upcoming_season}
    broadcast_change(new_state)
    {:noreply, new_state}
  end

  @impl true
  def handle_cast({:update_battery_level, level}, state) do
    new_state = %{state | battery_level: level}
    broadcast_change(new_state)
    {:noreply, new_state}
  end

  @impl true
  def handle_cast({:update_flow_level, status}, state) do
    new_state = %{state | flow_level: status}
    broadcast_change(new_state)
    {:noreply, new_state}
  end

  # Private Functions

  defp broadcast_change(state) do
    Phoenix.PubSub.broadcast(Timberee.PubSub, @topic, {:state_changed, state})
  end
end
