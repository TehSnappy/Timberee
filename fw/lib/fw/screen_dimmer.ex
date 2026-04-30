defmodule Fw.ScreenDimmer do
  use GenServer
  require Logger

  @check_interval 10_000
  @pwm_gpio 14
  @pwm_frequency 1000

  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @impl true
  def init(_opts) do
    Pigpiox.Pwm.gpio_pwm(@pwm_gpio, @pwm_frequency)
    Timberee.UsageState.subscribe()
    schedule_check()
    {:ok, %{}}
  end

  @impl true
  def handle_info(:check, state) do
    check_and_dim()
    schedule_check()
    {:noreply, state}
  end

  def handle_info({:state_changed, _new_state}, state) do
    check_and_dim()
    {:noreply, state}
  end

  defp check_and_dim do
    %{last_action: last_action, display_timeout: display_timeout, max_usage: max_usage} =
      state = Timberee.UsageState.get_state()

    Logger.debug("ScreenDimmer: Usage state #{inspect(state)}")

    if should_dim?(last_action, display_timeout) do
      dim_screen()
    else
      undim_screen(max_usage)
    end
  end

  defp should_dim?(nil, _timeout), do: false

  defp should_dim?(last_action, display_timeout) do
    deadline = DateTime.add(last_action, display_timeout, :second)
    DateTime.compare(DateTime.utc_now(), deadline) == :gt
  end

  defp dim_screen do
    Logger.debug("ScreenDimmer: dimming screen")
    Pigpiox.Pwm.gpio_pwm(@pwm_gpio, 0)
  end

  defp undim_screen(max_usage) do
    Logger.debug("ScreenDimmer: screen active, backlight #{max_usage}")
    Pigpiox.Pwm.gpio_pwm(@pwm_gpio, max_usage)
  end

  defp schedule_check do
    Process.send_after(self(), :check, @check_interval)
  end
end
