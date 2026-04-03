defmodule TimbereeWeb.Api.PowerController do
  use TimbereeWeb, :controller
  alias Timberee.TimberState

  # @seasons ["drought", "badtide", "temperate"]

  action_fallback(TimbereeWeb.Api.FallbackController)

  def flow(conn, %{"current" => current}) do
    case Integer.parse(current) do
      {int, _} ->
        TimberState.update_flow_level(int)
        state = TimberState.get_state()
        send_json_state(conn, state, "power flow updated")

      _ ->
        {:error, "Invalid parameter: current must be an integer"}
    end
  end

  def flow(_conn, _) do
    {:error, "Missing required parameters: current"}
  end

  def battery(conn, %{"power" => power}) do
    case Integer.parse(power) do
      {amt, _} ->
        TimberState.update_battery_level(amt)
        send_json_state(conn, TimberState.get_state(), "Battery updated")

      _ ->
        {:error, "Invalid parameter: power must be a number"}
    end
  end

  def battery(_conn, _) do
    {:error, "Missing required parameters: power"}
  end
end
