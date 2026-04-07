defmodule TimbereeScenic.Scene.Timber do
  use Scenic.Scene
  require Logger
  alias Scenic.Graph
  import Scenic.Primitives

  @topic "timber:state"

  @therm_w 60
  @therm_h 300
  @therm_gap 20
  # top of thermometer body — centers the element block vertically in the 540px body area
  @therm_top_y 60
  @label_font_size 18
  @battery_w 140
  @battery_nut 30
  @battery_height 240
  @impl Scenic.Scene

  def init(scene, _param, _opts) do
    {width, height} = scene.viewport.size
    state = Timberee.TimberState.get_state()

    graph = build_graph(state, width, height)

    scene =
      scene
      |> assign(width: width, height: height)
      |> push_graph(graph)

    {:ok, scene}
  end

  @impl GenServer
  def handle_info({:state_changed, tb_state}, %{assigns: %{width: width, height: height}} = scene) do
    graph = build_graph(tb_state, width, height)
    {:noreply, push_graph(scene, graph)}
  end

  defp build_graph(timber_state, width, height) do
    split = width / 2
    Logger.warning("Building graph with split: #{inspect(split)}")

    Graph.build(font: :roboto, font_size: 16)
    |> draw_reservoirs(timber_state, split, height)
    |> draw_batteries(timber_state, split, split, height)
  end

  defp draw_reservoirs(graph, %{reservoirs: reservoirs}, width, height) do
    sorted = reservoirs |> Map.to_list() |> Enum.sort_by(fn {name, _} -> name end)
    count = length(sorted)
    total_w = count * @therm_w + max(count - 1, 0) * @therm_gap
    start_x = (width - total_w) / 2
    start_y = (height - @therm_h) / 2

    sorted
    |> Enum.with_index()
    |> Enum.reduce(graph, fn {{name, pct}, i}, g ->
      x = start_x + i * (@therm_w + @therm_gap)
      draw_thermometer(g, name, pct, x, start_y)
    end)
  end

  defp draw_batteries(
         graph,
         %{flow_level: flow_level, battery_level: battery_level},
         width,
         offset,
         height
       ) do
    start_x = offset + (width - @battery_w) / 2

    draw_battery(graph, battery_level, flow_level, start_x, height)
  end

  defp draw_battery(graph, battery_level, flow_level, x, height) do
    battery_level = battery_level |> max(0) |> min(100)
    fill_y = round(battery_level / 100 * @therm_h)
    fill_offset = @therm_h - fill_y
    battery_y_offfset = (height - @battery_height) / 2

    graph
    |> rect(
      {@battery_w, @therm_h - @battery_nut},
      fill: {30, 30, 50},
      stroke: {2, {80, 80, 150}},
      translate: {x, battery_y_offfset}
    )
    |> rect(
      {@battery_nut, @battery_nut},
      fill: {30, 30, 50},
      stroke: {2, {80, 80, 150}},
      translate: {x + @battery_w / 2 - @battery_nut / 2, battery_y_offfset - @battery_nut}
    )
    |> rect(
      {@battery_w - 4, min(fill_y, @therm_h - @battery_nut)},
      fill: get_battery_fill_color(flow_level),
      stroke: {2, get_battery_fill_color(flow_level)},
      translate: {x + 2, battery_y_offfset + fill_offset}
    )
    |> text(
      "#{battery_level}%",
      font_size: @label_font_size,
      fill: :white,
      text_align: :center,
      translate: {x + @battery_w / 2, @therm_h + @therm_top_y + 28}
    )
  end

  defp get_battery_fill_color(flow_level) do
    case flow_level do
      -3 -> {250, 100, 100}
      -2 -> {220, 100, 100}
      -1 -> {170, 100, 100}
      0 -> {100, 100, 100}
      1 -> {100, 170, 100}
      2 -> {100, 220, 100}
      3 -> {100, 250, 100}
    end
  end

  defp draw_thermometer(graph, name, pct, x, start_y) do
    pct = pct |> max(0) |> min(100)
    fill_h = round(pct / 100 * @therm_h)
    fill_y = @therm_top_y + @therm_h - fill_h
    fill_y_start = start_y + (@therm_h - fill_h)

    graph
    |> rect(
      {@therm_w, @therm_h},
      fill: {30, 30, 50},
      stroke: {2, {80, 80, 150}},
      translate: {x, start_y}
    )
    |> draw_fill(pct, fill_h, fill_y_start, x)
    |> text(
      "#{round(pct)}%",
      font_size: @label_font_size,
      fill: :white,
      text_align: :center,
      translate: {x + @therm_w / 2, start_y - 8}
    )
    |> text(
      name,
      font_size: @label_font_size,
      fill: :white,
      text_align: :center,
      translate: {x + @therm_w / 2, start_y + @therm_h + 22}
    )
  end

  defp draw_fill(graph, _pct, 0, _fill_y, _x), do: graph

  defp draw_fill(graph, pct, fill_h, fill_y, x) do
    rect(graph, {@therm_w - 4, fill_h}, fill: fill_color(pct), translate: {x + 2, fill_y - 2})
  end

  defp fill_color(pct) when pct < 25, do: {200, 60, 60}
  defp fill_color(pct) when pct < 50, do: {200, 160, 60}
  defp fill_color(_pct), do: {60, 120, 220}
end
