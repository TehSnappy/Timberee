defmodule TimbereeWeb.Api.WaterController do
  use TimbereeWeb, :controller
  alias Timberee.TimberState

  action_fallback(TimbereeWeb.Api.FallbackController)

  def water(conn, %{"level" => level}) when is_binary(level) do
    case Float.parse(level) do
      {level_float, _} ->
        TimberState.update_water_level(level_float)
        state = TimberState.get_state()

        conn
        |> put_status(:ok)
        |> json(%{
          success: true,
          message: "Water level updated",
          state: state
        })

      :error ->
        {:error, "Invalid parameter: level must be a float"}
    end
  end

  def water(conn, _params) do
    {:error, "Missing required parameter: level"}
  end
end
