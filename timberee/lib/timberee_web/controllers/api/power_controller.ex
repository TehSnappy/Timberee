defmodule TimbereeWeb.Api.PowerController do
  use TimbereeWeb, :controller
  alias Timberee.TimberState

  @seasons ["drought", "badtide", "temperate"]

  action_fallback(TimbereeWeb.Api.FallbackController)

  def flow(conn, %{"current" => current}) do
    case Integer.parse(current) do
      {int, _} ->
        TimberState.update_flow_level(int)
        state = TimberState.get_state()

        conn
        |> put_status(:ok)
        |> json(%{
          success: true,
          message: "power flow updated",
          state: state
        })

      _ ->
        {:error, "Invalid parameter: current must be an integer"}
    end
  end

  def flow(conn, _) do
    {:error, "Missing required parameters: current"}
  end

  def battery(conn, %{"power" => power}) do
    {amt, _} = Integer.parse(power)
    TimberState.update_battery_level(amt)
    state = TimberState.get_state()

    conn
    |> put_status(:ok)
    |> json(%{
      success: true,
      message: "Battery updated",
      state: state
    })
  end

  def battery(conn, _) do
    {:error, "Missing required parameters: power"}
  end
end
