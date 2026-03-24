defmodule TimbereeWeb.DashboardLive do
  use TimbereeWeb, :live_view
  alias Timberee.TimberState

  @impl true
  def mount(_params, _session, socket) do
    if connected?(socket) do
      TimberState.subscribe()
    end

    state = TimberState.get_state()

    {:ok,
     socket
     |> assign(:water_level, state.water_level)
     |> assign(:time_remaining, state.time_remaining)
     |> assign(:season, state.season)
     |> assign(:upcoming_season, state.upcoming_season)
     |> assign(:battery_level, state.battery_level)
     |> assign(:flow_level, state.flow_level)
     |> assign(:reservoirs, state.reservoirs)}
  end

  @impl true
  def handle_info({:state_changed, state}, socket) do
    {:noreply,
     socket
     |> assign(:water_level, state.water_level)
     |> assign(:time_remaining, state.time_remaining)
     |> assign(:season, state.season)
     |> assign(:upcoming_season, state.upcoming_season)
     |> assign(:battery_level, state.battery_level)
     |> assign(:reservoirs, state.reservoirs)}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash}>
      <div class="min-h-screen bg-gradient-to-b from-amber-50 to-emerald-50 py-12 px-4">
        <div class="grid mx-auto grid-cols-2 gap-8">
          <div class="bg-white/80 backdrop-blur rounded-3xl shadow-xl p-8 border-2 border-emerald-200">
            <h2 class="text-2xl font-semibold text-emerald-800 mb-6 text-center">
              Reservoirs
            </h2>
            <div class={"grid gap-2 grid-cols-#{Enum.count(@reservoirs)}"}>
              <span :for={{name, fill_percent} <- @reservoirs}>
                <%= draw_reservoir(%{name: name, fill_percent: fill_percent}) %>
              </span>
            </div>
          </div>
          <div class="gap-4">
            <%= draw_stat(%{name: "Current Season", value: "#{@season}"}) %>

            <%= if @time_remaining > 0 do %>
              <div class=" gap-4bg-white/80 mt-6 backdrop-blur rounded-3xl shadow-xl p-8 border-2 border-amber-200">

                <h2 class="text-2xl font-semibold text-amber-800 mb-6 text-center">
                  {"Time Remaining until #{@upcoming_season}"}
                </h2>
                <%= draw_timer(%{time_remaining: @time_remaining}) %>
              </div>
            <% end %>
            <%= draw_stat(%{name: "Water Supply Level", value: "#{@water_level}%"}) %>
            <%= draw_stat(%{name: "Battery Level", value: "#{@battery_level}%"}) %>
          </div>
        </div>
      </div>
    </Layouts.app>
    """
  end

  defp draw_stat(assigns) do
    ~H"""
      <div class=" gap-4bg-white/80 mt-6 backdrop-blur rounded-3xl shadow-xl p-8 border-2 border-amber-200">
        <h2 class="text-2xl font-semibold text-emerald-800 mb-6 text-center">
          <%= @name %>
        </h2>

        <div class="flex flex-col items-center">
          <span class="text-4xl font-bold text-blue-600">
            {@value}
          </span>
        </div>
      </div>
    """
  end

  defp draw_reservoir(assigns) do
    ~H"""
      <div class="bg-white/80 backdrop-blur rounded-3xl shadow-xl p-8 border-2 border-emerald-200">
        <h2 class="text-2xl font-semibold text-emerald-800 mb-6 text-center">
          <%= @name %>
        </h2>

        <div class="flex flex-col items-center">
          <!-- Thermometer Bulb and Tube -->
          <div class="relative w-20 h-80 bg-gray-200 rounded-full border-4 border-emerald-300 overflow-hidden">
            <!-- Water Fill -->
            <div
              class="absolute bottom-0 w-full bg-gradient-to-t from-blue-500 to-cyan-400 transition-all duration-1000 ease-out rounded-full"
              style={"height: #{@fill_percent}%"}
            >
            </div>

    <!-- Measurement Marks -->
            <div class="absolute inset-0 flex flex-col justify-between py-4 px-2">
              <span class="text-xs font-bold text-gray-700">100%</span>
              <span class="text-xs font-bold text-gray-700">75%</span>
              <span class="text-xs font-bold text-gray-700">50%</span>
              <span class="text-xs font-bold text-gray-700">25%</span>
              <span class="text-xs font-bold text-gray-700">0%</span>
            </div>
          </div>

    <!-- Current Level Display -->
          <div class="mt-6 text-center">
            <span class="text-4xl font-bold text-blue-600">
              {@fill_percent}%
            </span>
          </div>
        </div>
      </div>
    """
  end

  defp draw_timer(assigns) do
    ~H"""
                    <div class="flex flex-col items-center justify-center">
                    <div class="text-center space-y-4">
                      <div class="flex gap-4 justify-center">
                        <div class="bg-amber-100 rounded-xl p-4 min-w-[80px]">
                          <div class="text-4xl font-bold text-amber-900">{days(@time_remaining)}</div>
                          <div class="text-sm text-amber-700">days</div>
                        </div>
                        <div class="bg-amber-100 rounded-xl p-4 min-w-[80px]">
                          <div class="text-4xl font-bold text-amber-900">{hours(@time_remaining)}</div>
                          <div class="text-sm text-amber-700">hours</div>
                        </div>
                        <div class="bg-amber-100 rounded-xl p-4 min-w-[80px]">
                          <div class="text-4xl font-bold text-amber-900">
                            {minutes(@time_remaining)}
                          </div>
                          <div class="text-sm text-amber-700">min</div>
                        </div>
                      </div>
                    </div>
                  </div>
    """
  end

  # Helper functions to break down seconds into days/hours/minutes
  defp days(hours), do: div(hours, 24)
  defp hours(hours), do: hours |> rem(24)
  defp minutes(_seconds), do: 0
end
