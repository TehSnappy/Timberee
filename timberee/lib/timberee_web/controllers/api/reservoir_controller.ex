defmodule TimbereeWeb.Api.ReservoirController do
  use TimbereeWeb, :controller
  alias Timberee.TimberState

  action_fallback(TimbereeWeb.Api.FallbackController)

  def reservoirs(conn, %{"name" => current, "fill_percent" => fill_percent}) do
    case Integer.parse(fill_percent) do
      {fill_percent_int, _} ->
        TimberState.update_reservoirs(current, fill_percent_int)
        state = TimberState.get_state()

        conn
        |> put_status(:ok)
        |> json(%{
          success: true,
          message: "Reservoirs updated",
          state: state
        })

      _ ->
        {:error, "Invalid parameter: fill_percent must be an integer"}
    end
  end

  def reservoirs(conn, _) do
    {:error, "Missing required parameters: name and fill_percent"}
  end
end
