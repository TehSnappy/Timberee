defmodule TimbereeWeb.Router do
  use TimbereeWeb, :router

  pipeline :browser do
    plug(:accepts, ["html"])
    plug(:fetch_session)
    plug(:fetch_live_flash)
    plug(:put_root_layout, html: {TimbereeWeb.Layouts, :root})
    plug(:protect_from_forgery)
    plug(:put_secure_browser_headers)
  end

  pipeline :api do
    plug(:accepts, ["json"])
  end

  scope "/", TimbereeWeb do
    pipe_through(:browser)
    live("/", DashboardLive)
    live("/settings", SettingsLive)
  end

  scope "/api", TimbereeWeb do
    pipe_through(:api)

    get("/battery/:power", Api.PowerController, :battery)
    get("/flow/:current", Api.PowerController, :flow)
    get("/water/:level", Api.WaterController, :water)
    get("/season/:current/:remaining", Api.SeasonController, :season)
    get("/season/:current", Api.SeasonController, :season)
    get("/res/:name/:fill_percent", Api.ReservoirController, :reservoirs)
  end
end
