defmodule TimbereeWeb.Api.ReservoirController do
  use TimbereeWeb, :controller
  alias Timberee.TimberState
  alias Timberee.UsageState

  action_fallback(TimbereeWeb.Api.FallbackController)

  def reservoirs(conn, %{"name" => current, "fill_percent" => fill_percent}) do
    UsageState.touch()

    case Integer.parse(fill_percent) do
      {fill_percent_int, _} ->
        TimberState.update_reservoirs(current, fill_percent_int)
        send_json_state(conn, TimberState.get_state(), "Reservoirs updated")

      _ ->
        {:error, "Invalid parameter: fill_percent must be an integer"}
    end
  end

  def reservoirs(_conn, _) do
    {:error, "Missing required parameters: name and fill_percent"}
  end
end
