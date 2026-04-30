defmodule TimbereeWeb.SettingsLive do
  use TimbereeWeb, :live_view
  alias Timberee.UsageState

  @impl true
  def mount(_params, _session, socket) do
    if connected?(socket), do: UsageState.subscribe()

    %{max_usage: max_usage, display_timeout: display_timeout} = UsageState.get_state()

    {:ok,
     socket
     |> assign(:max_usage, max_usage)
     |> assign(:display_timeout, display_timeout)}
  end

  @impl true
  def handle_info({:state_changed, state}, socket) do
    {:noreply,
     socket
     |> assign(:max_usage, state.max_usage)
     |> assign(:display_timeout, state.display_timeout)}
  end

  @impl true
  def handle_event("set_max_usage", %{"max_usage" => value}, socket) do
    UsageState.set_max_usage(String.to_integer(value))
    {:noreply, socket}
  end

  @impl true
  def handle_event("set_display_timeout", %{"display_timeout" => value}, socket) do
    UsageState.set_display_timeout(String.to_integer(value))
    {:noreply, socket}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash}>
      <div class="min-h-screen bg-gradient-to-b from-amber-50 to-emerald-50 py-12 px-4">
        <div class="max-w-lg mx-auto space-y-8">
          <h1 class="text-3xl font-bold text-emerald-800 text-center">Settings</h1>

          <div class="bg-white/80 backdrop-blur rounded-3xl shadow-xl p-8 border-2 border-emerald-200">
            <h2 class="text-xl font-semibold text-emerald-800 mb-2">Max Brightness</h2>
            <p class="text-sm text-gray-500 mb-6">Controls the PWM duty cycle of the display backlight.</p>
            <form phx-change="set_max_usage">
              <div class="flex items-center gap-4">
                <input
                  type="range"
                  name="max_usage"
                  min="0"
                  max="100"
                  step="1"
                  value={@max_usage}
                  class="w-full accent-emerald-600"
                />
                <span class="w-12 text-right font-bold text-emerald-700 tabular-nums">
                  {@max_usage}%
                </span>
              </div>
            </form>
          </div>

          <div class="bg-white/80 backdrop-blur rounded-3xl shadow-xl p-8 border-2 border-amber-200">
            <h2 class="text-xl font-semibold text-amber-800 mb-2">Display Timeout</h2>
            <p class="text-sm text-gray-500 mb-6">Seconds of inactivity before the screen dims.</p>
            <form phx-change="set_display_timeout">
              <div class="flex items-center gap-4">
                <input
                  type="range"
                  name="display_timeout"
                  min="0"
                  max="3600"
                  step="10"
                  value={@display_timeout}
                  class="w-full accent-amber-600"
                />
                <span class="w-16 text-right font-bold text-amber-700 tabular-nums">
                  {@display_timeout}s
                </span>
              </div>
            </form>
          </div>
        </div>
      </div>
    </Layouts.app>
    """
  end
end
