defmodule TimbereeWeb.Api.FallbackController do
  use TimbereeWeb, :controller

  def call(conn, {:error, message}) do
    conn
    |> put_status(:bad_request)
    |> json(%{
      success: false,
      error: message
    })
  end

  def call(conn, %BadResult{} = error) do
    conn
    |> put_status(:bad_request)
    |> json(%{
      success: false,
      error: error.message
    })
  end
end
