defmodule TimbereeScenic.Scene.Timber do
  use Scenic.Scene

  alias Scenic.Graph
  import Scenic.Primitives

  alias TimbereeScenic.Component.Nav

  @topic "timber:state"

  @therm_w 60
  @therm_h 300
  @therm_gap 80
  # top of thermometer body — centers the element block vertically in the 540px body area
  @therm_top_y 160
  @label_font_size 18

  @impl Scenic.Scene
  def init(scene, _param, _opts) do
    {width, _height} = scene.viewport.size
    state = Timberee.TimberState.get_state()
    Phoenix.PubSub.subscribe(Timberee.PubSub, @topic)

    graph = build_graph(state.reservoirs, width)

    scene =
      scene
      |> assign(width: width)
      |> push_graph(graph)

    {:ok, scene}
  end

  @impl GenServer
  def handle_info({:state_changed, tb_state}, %{assigns: %{width: width}} = scene) do
    graph = build_graph(tb_state.reservoirs, width)
    {:noreply, push_graph(scene, graph)}
  end

  defp build_graph(reservoirs, width) do
    sorted = reservoirs |> Map.to_list() |> Enum.sort_by(fn {name, _} -> name end)
    count = length(sorted)
    total_w = count * @therm_w + max(count - 1, 0) * @therm_gap
    start_x = (width - total_w) / 2

    sorted
    |> Enum.with_index()
    |> Enum.reduce(Graph.build(font: :roboto, font_size: 16), fn {{name, pct}, i}, g ->
      x = start_x + i * (@therm_w + @therm_gap)
      draw_thermometer(g, name, pct, x)
    end)
    |> Nav.add_to_graph(__MODULE__)
  end

  defp draw_thermometer(graph, name, pct, x) do
    pct = pct |> max(0) |> min(100)
    fill_h = round(pct / 100 * @therm_h)
    fill_y = @therm_top_y + @therm_h - fill_h

    graph
    |> rect(
      {@therm_w, @therm_h},
      fill: {30, 30, 50},
      stroke: {2, {80, 80, 150}},
      translate: {x, @therm_top_y}
    )
    |> draw_fill(pct, fill_h, fill_y, x)
    |> text(
      "#{round(pct)}%",
      font_size: @label_font_size,
      fill: :white,
      text_align: :center,
      translate: {x + @therm_w / 2, @therm_top_y - 8}
    )
    |> text(
      name,
      font_size: @label_font_size,
      fill: :white,
      text_align: :center,
      translate: {x + @therm_w / 2, @therm_top_y + @therm_h + 22}
    )
  end

  defp draw_fill(graph, _pct, 0, _fill_y, _x), do: graph

  defp draw_fill(graph, pct, fill_h, fill_y, x) do
    rect(graph, {@therm_w - 4, fill_h}, fill: fill_color(pct), translate: {x + 2, fill_y})
  end

  defp fill_color(pct) when pct < 25, do: {200, 60, 60}
  defp fill_color(pct) when pct < 50, do: {200, 160, 60}
  defp fill_color(_pct), do: {60, 120, 220}
end
