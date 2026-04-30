defmodule TimbereeWeb.Api.SeasonController do
  use TimbereeWeb, :controller
  alias Timberee.TimberState
  alias Timberee.UsageState

  action_fallback(TimbereeWeb.Api.FallbackController)

  @seasons ["drought", "badtide", "temperate"]

  def season(conn, %{"current" => current, "remaining" => remaining})
      when current in @seasons do
    UsageState.touch()

    case Integer.parse(remaining) do
      {hours_remaining, _} ->
        TimberState.update_upcoming_season(current)
        TimberState.update_time_remaining(hours_remaining)
        send_json_state(conn, TimberState.get_state(), "Season and time remaining updated")

      _ ->
        {:error, "Invalid parameter: level must be a float"}
    end
  end

  def season(conn, %{"current" => current}) when current in @seasons do
    UsageState.touch()
    TimberState.update_season(current)
    TimberState.update_time_remaining(0)
    send_json_state(conn, TimberState.get_state(), "Season updated")
  end

  def season(_conn, _) do
    {:error, "Missing required parameters: current and remaining"}
  end
end
