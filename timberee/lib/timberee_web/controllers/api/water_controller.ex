defmodule TimbereeWeb.Api.WaterController do
  use TimbereeWeb, :controller
  alias Timberee.TimberState
  alias Timberee.UsageState

  action_fallback(TimbereeWeb.Api.FallbackController)

  def water(conn, %{"level" => level}) when is_binary(level) do
    UsageState.touch()

    case Integer.parse(level) do
      {level_float, _} ->
        TimberState.update_water_level(level_float)
        send_json_state(conn, TimberState.get_state(), "Water level updated")

      :error ->
        {:error, "Invalid parameter: level must be a float"}
    end
  end

  def water(_conn, _params) do
    {:error, "Missing required parameter: level"}
  end
end
