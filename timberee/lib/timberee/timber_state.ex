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
  def subscribe do
    Phoenix.PubSub.subscribe(Timberee.PubSub, @topic)
  end

  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  def get_state do
    GenServer.call(__MODULE__, :get_state)
  end

  def update_water_level(level) when level >= 0 and level <= 100 do
    GenServer.cast(__MODULE__, {:update_water_level, level})
  end

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
  def handle_cast(
        {:update_reservoirs, name, fill_percent},
        %{reservoirs: reservoirs} = state
      ) do
    set_and_broadcast(%{state | reservoirs: Map.put(reservoirs, name, fill_percent)})
  end

  @impl true
  def handle_cast({:update_water_level, level}, state) do
    set_and_broadcast(%{state | water_level: level})
  end

  @impl true
  def handle_cast({:update_time_remaining, seconds}, state) do
    set_and_broadcast(%{state | time_remaining: seconds})
  end

  @impl true
  def handle_cast({:update_season, season}, state) do
    set_and_broadcast(%{state | season: season})
  end

  @impl true
  def handle_cast({:update_upcoming_season, upcoming_season}, state) do
    set_and_broadcast(%{state | upcoming_season: upcoming_season})
  end

  @impl true
  def handle_cast({:update_battery_level, level}, state) do
    set_and_broadcast(%{state | battery_level: level})
  end

  @impl true
  def handle_cast({:update_flow_level, status}, state) do
    set_and_broadcast(%{state | flow_level: status})
  end

  # Private Functions

  defp set_and_broadcast(state) do
    broadcast_change(state)
    Logger.info("State updated: #{inspect(state)}")
    {:noreply, state}
  end

  defp broadcast_change(state) do
    Phoenix.PubSub.broadcast(Timberee.PubSub, @topic, {:state_changed, state})
  end

  defp default_state do
    %{
      reservoirs: %{"lwr" => 78, "upr" => 88},
      season: "temperate",
      water_level: 92,
      upcoming_season: "drought",
      time_remaining: 20,
      flow_level: -1,
      battery_level: 78
    }
  end
end
