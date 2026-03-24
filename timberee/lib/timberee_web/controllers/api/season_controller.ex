defmodule TimbereeWeb.Api.SeasonController do
  use TimbereeWeb, :controller
  alias Timberee.TimberState

  action_fallback(TimbereeWeb.Api.FallbackController)

  @seasons ["drought", "badtide", "temperate"]

  def season(conn, %{"current" => current, "remaining" => remaining})
      when current in @seasons do
    case Integer.parse(remaining) do
      {hours_remaining, _} ->
        TimberState.update_upcoming_season(current)
        TimberState.update_time_remaining(hours_remaining)
        state = TimberState.get_state()

        conn
        |> put_status(:ok)
        |> json(%{
          success: true,
          message: "Season and time remaining updated",
          state: state
        })

      _ ->
        {:error, "Invalid parameter: level must be a float"}
    end
  end

  def season(conn, %{"current" => current}) when current in @seasons do
    TimberState.update_season(current)
    TimberState.update_time_remaining(0)
    state = TimberState.get_state()

    conn
    |> put_status(:ok)
    |> json(%{
      success: true,
      message: "Season updated",
      state: state
    })
  end

  def season(conn, _) do
    {:error, "Missing required parameters: current and remaining"}
  end
end
