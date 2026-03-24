defmodule Timberee.Display do
  @moduledoc """
  GenServer that manages the Inky pHAT 400x300 display.
  Subscribes to TimberState changes and renders:
  - Water meter thermometer gauge
  - Countdown clock (days:hours:mins)
  - Season-based background color (brown=drought, red=badtide, green=temperate)
  """
  use GenServer
  require Logger

  @display_width 400
  @display_height 300
  @comp_targ Mix.target()

  # Season to background color mapping
  @season_colors %{
    # Brown/amber tone for drought
    "drought" => :yellow,
    # Red for danger
    "badtide" => :red,
    # We'll use black and show green accents
    "temperate" => :black
  }

  # Client API

  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  # Server Callbacks

  @impl true
  def init(_opts) do
    display =
      case Inky.start_link(:what, :red, %{name: InkyScreen}) do
        {:ok, display} ->
          Logger.info("Inky display initialized successfully")
          # Subscribe to timber state changes
          Timberee.TimberState.subscribe()

          # Get initial state and render
          state = Timberee.TimberState.get_state()
          render_display(display, state)

          Logger.info("Display GenServer started and subscribed to TimberState")

          display

        {:error, reason} ->
          Logger.error("Failed to initialize Inky display: #{inspect(reason)}")
          nil
      end

    state = Timberee.TimberState.get_state()

    {:ok, %{display: display, last_state: state}}
  end

  @impl true
  def handle_info({:state_changed, new_state}, socket_state) do
    if socket_state.display do
      if new_state != socket_state.last_state do
        Logger.info("State changed: #{inspect(new_state)}")
        render_display(socket_state.display, new_state)
      end
    else
      Logger.debug("State changed (host mode): #{inspect(new_state)}")
    end

    {:noreply, %{socket_state | last_state: new_state}}
  end

  # Private Functions

  defp render_display(display, state) do
    Logger.info("Rendering display: #{inspect(state)}")

    # Clear display with season background color
    bg_color = Map.get(@season_colors, state.season, :yellow)

    painter = fn x, y, w, h, _pixels_so_far ->
      wh = w / 2
      hh = h / 2

      case {x >= wh, y >= hh} do
        {true, true} -> :red
        {false, true} -> if(rem(x, 2) == 0, do: :black, else: :white)
        {true, false} -> :black
        {false, false} -> :white
      end
    end

    Inky.set_pixels(InkyScreen, painter, border: :white)

    # # Draw water thermometer (left side)
    # draw_thermometer(display, state.water_level)

    # # Draw countdown clock (right side)
    # draw_countdown(display, state.time_remaining)

    # # Draw season label at top
    # draw_season_label(display, state.season)

    # Push to display
    # Display.show(display)
  end

  defp background_pixels(:yellow) do
    # Create amber/brown background (using red channel for warmth)
    for _y <- 0..(@display_height - 1),
        _x <- 0..(@display_width - 1),
        into: <<>> do
      # Red pixels for amber/brown tone
      <<1::size(2)>>
    end
  end

  defp background_pixels(:red) do
    # Create red background
    for _y <- 0..(@display_height - 1),
        _x <- 0..(@display_width - 1),
        into: <<>> do
      # Red pixels
      <<1::size(2)>>
    end
  end

  defp background_pixels(:black) do
    # Create black background for temperate (we'll add green via black pixels)
    for _y <- 0..(@display_height - 1),
        _x <- 0..(@display_width - 1),
        into: <<>> do
      # Black pixels
      <<2::size(2)>>
    end
  end

  defp draw_thermometer(display, water_level) do
    # Thermometer dimensions
    therm_x = 50
    therm_y = 80
    therm_width = 60
    therm_height = 180

    # Draw thermometer outline (white border)
    draw_rect(display, therm_x, therm_y, therm_width, therm_height, :white)

    # Calculate fill height based on water level percentage
    fill_height = round(therm_height * water_level / 100.0)
    fill_y = therm_y + therm_height - fill_height

    # Draw water fill (black for contrast)
    draw_filled_rect(display, therm_x + 2, fill_y, therm_width - 4, fill_height, :black)

    # Draw percentage text below thermometer
    percentage_text = "#{round(water_level)}%"
    draw_text(display, therm_x, therm_y + therm_height + 10, percentage_text, :white)
  end

  defp draw_countdown(display, seconds) do
    days = div(seconds, 86400)
    hours = seconds |> rem(86400) |> div(3600)
    minutes = seconds |> rem(3600) |> div(60)

    # Position for countdown (right side)
    countdown_x = 220
    countdown_y = 120

    # Draw countdown text (white for visibility)
    countdown_text = "#{days}d #{hours}h #{minutes}m"
    draw_large_text(display, countdown_x, countdown_y, countdown_text, :white)

    # Draw "TIME LEFT" label above
    draw_text(display, countdown_x, countdown_y - 20, "TIME LEFT", :white)
  end

  defp draw_season_label(display, season) do
    # Draw season name at top center
    season_text = String.upcase(season)
    draw_large_text(display, 120, 20, season_text, :white)
  end

  defp draw_rect(display, x, y, width, height, color) do
    color_value = color_to_value(color)

    # Top and bottom edges
    for px <- x..(x + width - 1) do
      Inky.set_pixel(display, px, y, color_value)
      Inky.set_pixel(display, px, y + height - 1, color_value)
    end

    # Left and right edges
    for py <- y..(y + height - 1) do
      Inky.set_pixel(display, x, py, color_value)
      Inky.set_pixel(display, x + width - 1, py, color_value)
    end
  end

  defp draw_filled_rect(display, x, y, width, height, color) do
    color_value = color_to_value(color)

    for py <- y..(y + height - 1),
        px <- x..(x + width - 1) do
      Inky.set_pixel(display, px, py, color_value)
    end
  end

  defp draw_text(display, x, y, text, color) do
    # Simple 5x7 pixel text rendering
    color_value = color_to_value(color)

    String.graphemes(text)
    |> Enum.with_index()
    |> Enum.each(fn {char, index} ->
      char_x = x + index * 6
      draw_char(display, char_x, y, char, color_value)
    end)
  end

  defp draw_large_text(display, x, y, text, color) do
    # Larger 10x14 pixel text for countdown
    color_value = color_to_value(color)

    String.graphemes(text)
    |> Enum.with_index()
    |> Enum.each(fn {char, index} ->
      char_x = x + index * 12
      draw_large_char(display, char_x, y, char, color_value)
    end)
  end

  defp draw_char(display, x, y, char, color) do
    # Simple bitmap font - just drawing basic shapes for demo
    # In production, you'd use a proper bitmap font
    case char do
      "0" -> draw_digit_0(display, x, y, color)
      "1" -> draw_digit_1(display, x, y, color)
      "2" -> draw_digit_2(display, x, y, color)
      "3" -> draw_digit_3(display, x, y, color)
      "4" -> draw_digit_4(display, x, y, color)
      "5" -> draw_digit_5(display, x, y, color)
      "6" -> draw_digit_6(display, x, y, color)
      "7" -> draw_digit_7(display, x, y, color)
      "8" -> draw_digit_8(display, x, y, color)
      "9" -> draw_digit_9(display, x, y, color)
      "%" -> draw_percent(display, x, y, color)
      _ -> draw_letter(display, x, y, char, color)
    end
  end

  defp draw_large_char(display, x, y, char, color) do
    # Scaled up version - 2x size
    case char do
      c when c in ["0", "1", "2", "3", "4", "5", "6", "7", "8", "9"] ->
        draw_large_digit(display, x, y, c, color)

      "d" ->
        draw_large_letter(display, x, y, "D", color)

      "h" ->
        draw_large_letter(display, x, y, "H", color)

      "m" ->
        draw_large_letter(display, x, y, "M", color)

      " " ->
        :ok

      _ ->
        draw_large_letter(display, x, y, char, color)
    end
  end

  # Simple digit/letter drawing functions (placeholder implementations)
  defp draw_digit_0(display, x, y, color) do
    for py <- 0..6, px <- 0..4, px == 0 or px == 4 or py == 0 or py == 6 do
      Inky.set_pixel(display, x + px, y + py, color)
    end
  end

  defp draw_digit_1(display, x, y, color) do
    for py <- 0..6 do
      Inky.set_pixel(display, x + 2, y + py, color)
    end
  end

  defp draw_digit_2(display, x, y, color) do
    for px <- 0..4 do
      Inky.set_pixel(display, x + px, y, color)
      Inky.set_pixel(display, x + px, y + 3, color)
      Inky.set_pixel(display, x + px, y + 6, color)
    end

    Inky.set_pixel(display, x + 4, y + 1, color)
    Inky.set_pixel(display, x, y + 5, color)
  end

  # Placeholder for other digits - implement similarly
  defp draw_digit_3(display, x, y, color), do: draw_digit_0(display, x, y, color)
  defp draw_digit_4(display, x, y, color), do: draw_digit_1(display, x, y, color)
  defp draw_digit_5(display, x, y, color), do: draw_digit_2(display, x, y, color)
  defp draw_digit_6(display, x, y, color), do: draw_digit_0(display, x, y, color)
  defp draw_digit_7(display, x, y, color), do: draw_digit_1(display, x, y, color)
  defp draw_digit_8(display, x, y, color), do: draw_digit_0(display, x, y, color)
  defp draw_digit_9(display, x, y, color), do: draw_digit_0(display, x, y, color)

  defp draw_percent(display, x, y, color) do
    Inky.set_pixel(display, x, y, color)
    Inky.set_pixel(display, x + 4, y + 6, color)
  end

  defp draw_letter(display, x, y, _char, color) do
    # Generic placeholder for letters
    for py <- 0..6, px <- 0..4 do
      Inky.set_pixel(display, x + px, y + py, color)
    end
  end

  defp draw_large_digit(display, x, y, digit, color) do
    # 2x scaled version
    for scale_y <- 0..1, scale_x <- 0..1 do
      case digit do
        "0" -> draw_digit_0(display, x + scale_x * 5, y + scale_y * 7, color)
        "1" -> draw_digit_1(display, x + scale_x * 5, y + scale_y * 7, color)
        "2" -> draw_digit_2(display, x + scale_x * 5, y + scale_y * 7, color)
        _ -> draw_digit_0(display, x + scale_x * 5, y + scale_y * 7, color)
      end
    end
  end

  defp draw_large_letter(display, x, y, char, color) do
    # Placeholder for large letters
    for py <- 0..13, px <- 0..9 do
      Inky.set_pixel(display, x + px, y + py, color)
    end
  end

  defp color_to_value(:white), do: 0
  defp color_to_value(:black), do: 2
  defp color_to_value(:red), do: 1
end
