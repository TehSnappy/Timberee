defmodule TimbereeScenic.Scene.Timber do
  use Scenic.Scene
  require Logger
  alias Scenic.Graph
  alias Timberee.TimberState
  import Scenic.Primitives

  @therm_w 60
  @therm_h 300
  @therm_gap 20
  # top of thermometer body — centers the element block vertically in the 540px body area
  # @therm_top_y 60
  @label_font_size 18
  @battery_w 140
  @battery_nut 30
  @battery_height 240
  @impl Scenic.Scene

  def init(scene, _param, _opts) do
    #  {width, height} = scene.viewport.size

    # {width, height} = {width, height} |> adjust_for_config()
    {width, height} = {800, 480}

    state = TimberState.get_state()
    TimberState.subscribe()

    baseline = height - @therm_h
    baseline = height - baseline + 140
    Logger.warning("Building graph with baseline: #{inspect(baseline)}")

    graph = build_graph(state, width, baseline)

    scene =
      scene
      |> assign(width: width, height: height, baseline: baseline)
      |> push_graph(graph)

    {:ok, scene}
  end

  @impl true
  def handle_info(
        {:state_changed, tb_state},
        %{assigns: %{width: width, baseline: baseline}} = scene
      ) do
    graph = build_graph(tb_state, width, baseline)
    {:noreply, push_graph(scene, graph)}
  end

  defp build_graph(timber_state, width, baseline) do
    split = width / 2
    Logger.warning("Building graph with split: #{inspect(split)}")

    Graph.build(font: :roboto, font_size: 16)
    |> draw_header(timber_state, split)
    |> draw_teardrop(timber_state, split, baseline)
    |> draw_reservoirs(timber_state, split, baseline)
    |> draw_batteries(timber_state, split, width - 40, baseline)
  end

  defp draw_header(
         graph,
         %{season: season, time_remaining: time_remaining, upcoming_season: upcoming_season} =
           timber_state,
         width
       ) do
    graph =
      graph
      |> text(
        season_title(season),
        font_size: 48,
        fill: :white,
        text_align: :center,
        translate: {width, 40}
      )

    if time_remaining > 0 do
      graph
      |> text(
        "#{time_remaining} hours until #{upcoming_season}",
        font_size: 24,
        fill: season_time_remaining(timber_state),
        text_align: :center,
        translate: {width, 78}
      )
    else
      graph
    end
  end

  defp draw_reservoirs(graph, %{reservoirs: reservoirs}, _width, baseline) do
    sorted = reservoirs |> Map.to_list() |> Enum.sort_by(fn {name, _} -> name end)
    # count = length(sorted)
    # total_w = count * @therm_w + max(count - 1, 0) * @therm_gap
    start_x = 40

    sorted
    |> Enum.with_index()
    |> Enum.reduce(graph, fn {{name, pct}, i}, g ->
      x = start_x + i * (@therm_w + @therm_gap)
      draw_thermometer(g, name, pct, x, baseline)
    end)
  end

  defp draw_batteries(
         graph,
         %{flow_level: flow_level, battery_level: battery_level},
         _width,
         offset,
         baseline
       ) do
    start_x = offset - @battery_w

    graph
    |> draw_battery(battery_level, start_x, baseline)
    |> draw_battery_chevrons(flow_level, start_x, baseline)
  end

  @drop_r 50
  @drop_point_h 170
  # total visual height = @drop_r + @drop_point_h
  @drop_total_h @drop_r + @drop_point_h
  @drop_bg {20, 20, 50}
  # bezier control-point factor for quarter-circle approximation
  @bk 0.5523

  defp draw_teardrop(graph, %{water_level: water_level}, x, y) do
    r = @drop_r
    cx = x
    bottom_y = y
    equator_y = bottom_y - r
    tip_y = equator_y - @drop_point_h
    water_level = water_level |> max(0) |> min(100)

    graph
    |> draw_drop_shape(cx, tip_y, equator_y, bottom_y, r)
    |> draw_drop_fill(water_level, cx, tip_y, equator_y, bottom_y, r)
    |> draw_drop_stroke(cx, tip_y, equator_y, bottom_y, r)
    |> text(
      "#{water_level}%",
      font_size: @label_font_size,
      fill: :white,
      text_align: :center,
      translate: {cx, bottom_y + 18}
    )
    |> text(
      "water supply",
      font_size: @label_font_size,
      fill: :white,
      text_align: :center,
      translate: {cx, bottom_y - @therm_h - 10}
    )
  end

  defp season_title("temperate"), do: "Temperate"
  defp season_title("drought"), do: "Drought"
  defp season_title("badtide"), do: "Badtide"
  defp season_title(_), do: "pending..."

  defp drop_path_ops(cx, tip_y, equator_y, bottom_y, r) do
    k = @bk
    ph = equator_y - tip_y

    [
      :begin,
      {:move_to, cx, tip_y},
      # right side: tip → right equator (3 o'clock), tangent vertical at tip
      {:bezier_to, cx, tip_y + ph * 0.5, cx + r, tip_y + ph * 0.7, cx + r, equator_y},
      # right quarter-circle: equator → bottom
      {:bezier_to, cx + r, equator_y + k * r, cx + k * r, bottom_y, cx, bottom_y},
      # left quarter-circle: bottom → left equator (9 o'clock)
      {:bezier_to, cx - k * r, bottom_y, cx - r, equator_y + k * r, cx - r, equator_y},
      # left side: left equator → tip
      {:bezier_to, cx - r, tip_y + ph * 0.7, cx, tip_y + ph * 0.5, cx, tip_y},
      :close_path
    ]
  end

  defp draw_drop_shape(graph, cx, tip_y, equator_y, bottom_y, r) do
    path(graph, drop_path_ops(cx, tip_y, equator_y, bottom_y, r), fill: @drop_bg)
  end

  defp draw_drop_stroke(graph, cx, tip_y, equator_y, bottom_y, r) do
    path(graph, drop_path_ops(cx, tip_y, equator_y, bottom_y, r),
      fill: :clear,
      stroke: {3, {100, 150, 255}}
    )
  end

  defp draw_drop_fill(graph, 0, _cx, _tip_y, _equator_y, _bottom_y, _r), do: graph

  defp draw_drop_fill(graph, 100, cx, tip_y, equator_y, bottom_y, r) do
    path(graph, drop_path_ops(cx, tip_y, equator_y, bottom_y, r), fill: drop_water_color(100))
  end

  defp draw_drop_fill(graph, water_level, cx, tip_y, equator_y, bottom_y, r) do
    fill_h = water_level / 100 * @drop_total_h
    water_line_y = bottom_y - fill_h
    color = drop_water_color(water_level)
    k = @bk

    # The two lower quarter-circle beziers (shared for both cases)
    rq =
      {{cx + r, equator_y}, {cx + r, equator_y + k * r}, {cx + k * r, bottom_y}, {cx, bottom_y}}

    lq =
      {{cx, bottom_y}, {cx - k * r, bottom_y}, {cx - r, equator_y + k * r}, {cx - r, equator_y}}

    if water_line_y >= equator_y do
      # Fill is entirely within the lower semicircle — split the beziers at water_line_y
      t_r = drop_bezier_t(rq, water_line_y)
      t_l = drop_bezier_t(lq, water_line_y)
      {_prefix_r, {rp0, rp1, rp2, rp3}} = drop_bezier_split(rq, t_r)
      {{_lp0, lp1, lp2, lp3}, _suffix_l} = drop_bezier_split(lq, t_l)

      path(
        graph,
        [
          :begin,
          {:move_to, elem(rp0, 0), elem(rp0, 1)},
          {:bezier_to, elem(rp1, 0), elem(rp1, 1), elem(rp2, 0), elem(rp2, 1), elem(rp3, 0),
           elem(rp3, 1)},
          {:bezier_to, elem(lp1, 0), elem(lp1, 1), elem(lp2, 0), elem(lp2, 1), elem(lp3, 0),
           elem(lp3, 1)},
          :close_path
        ],
        fill: color
      )
    else
      # Fill extends into the pointed region — use linear approx for pointed sides,
      # exact beziers for the circular bottom
      fraction = (water_line_y - tip_y) / max(equator_y - tip_y, 1)
      hw = fraction * r

      path(
        graph,
        [
          :begin,
          {:move_to, cx - hw, water_line_y},
          {:line_to, cx - r, equator_y},
          {:bezier_to, cx - r, equator_y + k * r, cx - k * r, bottom_y, cx, bottom_y},
          {:bezier_to, cx + k * r, bottom_y, cx + r, equator_y + k * r, cx + r, equator_y},
          {:line_to, cx + hw, water_line_y},
          :close_path
        ],
        fill: color
      )
    end
  end

  # Binary search for the bezier parameter t where the y-coordinate equals target_y.
  # Assumes y is monotone along the curve.
  defp drop_bezier_t(bezier, target_y), do: drop_bezier_t(bezier, target_y, 0.0, 1.0, 0)
  defp drop_bezier_t(_, _, lo, hi, depth) when depth >= 24, do: (lo + hi) / 2.0

  defp drop_bezier_t({p0, p1, p2, p3} = bezier, target_y, lo, hi, depth) do
    mid = (lo + hi) / 2.0
    y_mid = drop_bval(elem(p0, 1), elem(p1, 1), elem(p2, 1), elem(p3, 1), mid)

    cond do
      abs(y_mid - target_y) < 0.1 ->
        mid

      (elem(p0, 1) <= elem(p3, 1) and y_mid < target_y) or
          (elem(p0, 1) > elem(p3, 1) and y_mid > target_y) ->
        drop_bezier_t(bezier, target_y, mid, hi, depth + 1)

      true ->
        drop_bezier_t(bezier, target_y, lo, mid, depth + 1)
    end
  end

  # Evaluate a single coordinate component of a cubic bezier at t.
  defp drop_bval(v0, v1, v2, v3, t) do
    u = 1.0 - t
    u * u * u * v0 + 3 * u * u * t * v1 + 3 * u * t * t * v2 + t * t * t * v3
  end

  # Split a cubic bezier at t using de Casteljau's algorithm.
  # Returns {prefix_bezier, suffix_bezier} as tuples of 4 {x,y} points.
  defp drop_bezier_split({p0, p1, p2, p3}, t) do
    q0 = drop_lerp(p0, p1, t)
    q1 = drop_lerp(p1, p2, t)
    q2 = drop_lerp(p2, p3, t)
    r0 = drop_lerp(q0, q1, t)
    r1 = drop_lerp(q1, q2, t)
    s = drop_lerp(r0, r1, t)
    {{p0, q0, r0, s}, {s, r1, q2, p3}}
  end

  defp drop_lerp({x0, y0}, {x1, y1}, t),
    do: {x0 + (x1 - x0) * t, y0 + (y1 - y0) * t}

  defp drop_water_color(pct) when pct < 25, do: {200, 60, 60}
  defp drop_water_color(pct) when pct < 50, do: {180, 140, 60}
  defp drop_water_color(_pct), do: {60, 140, 240}

  defp draw_battery(graph, battery_level, x, baseline) do
    battery_level = battery_level |> max(0) |> min(100)
    fill_y = round(battery_level / 100 * @battery_height)
    fill_offset = baseline - fill_y
    battery_y_offset = baseline - @battery_height

    graph
    |> rect(
      {@battery_w, @battery_height},
      fill: {30, 30, 50},
      stroke: {2, {80, 80, 150}},
      translate: {x, battery_y_offset}
    )
    |> rect(
      {@battery_nut, @battery_nut},
      fill: {30, 30, 50},
      stroke: {2, {80, 80, 150}},
      translate: {x + @battery_w / 2 - @battery_nut / 2, battery_y_offset - @battery_nut}
    )
    |> rect(
      {@battery_w - 4, min(fill_y, @therm_h - @battery_nut)},
      fill: get_battery_fill_color(battery_level),
      stroke: {2, get_battery_fill_color(battery_level)},
      translate: {x + 2, fill_offset}
    )
    |> text(
      "#{battery_level}%",
      font_size: @label_font_size,
      fill: :white,
      text_align: :center,
      translate: {x + @battery_w / 2, baseline + 18}
    )
    |> text(
      "power supply",
      font_size: @label_font_size,
      fill: :white,
      text_align: :center,
      translate: {x + @battery_w / 2, baseline - @therm_h - 10}
    )
  end

  defp get_battery_fill_color(battery_level) when battery_level > 75, do: {100, 220, 100}
  defp get_battery_fill_color(battery_level) when battery_level > 60, do: {100, 200, 100}
  defp get_battery_fill_color(battery_level) when battery_level > 50, do: {100, 170, 100}
  defp get_battery_fill_color(battery_level) when battery_level > 40, do: {100, 100, 100}
  defp get_battery_fill_color(battery_level) when battery_level > 30, do: {120, 100, 100}
  defp get_battery_fill_color(battery_level) when battery_level > 20, do: {180, 100, 100}
  defp get_battery_fill_color(battery_level) when battery_level > 10, do: {220, 100, 100}
  defp get_battery_fill_color(_battery_level), do: {250, 100, 100}

  def draw_battery_chevrons(graph, 0, _, _), do: graph

  def draw_battery_chevrons(graph, 1, x, baseline),
    do: graph |> draw_chevron_up(x, baseline - 120)

  def draw_battery_chevrons(graph, 2, x, baseline),
    do:
      graph
      |> draw_chevron_up(x, baseline - 120)
      |> draw_chevron_up(x, baseline - 140)

  def draw_battery_chevrons(graph, 3, x, baseline),
    do:
      graph
      |> draw_chevron_up(x, baseline - 120)
      |> draw_chevron_up(x, baseline - 140)
      |> draw_chevron_up(x, baseline - 160)

  def draw_battery_chevrons(graph, -1, x, baseline),
    do: graph |> draw_chevron_down(x, baseline - 100)

  def draw_battery_chevrons(graph, -2, x, baseline),
    do:
      graph
      |> draw_chevron_down(x, baseline - 80)
      |> draw_chevron_down(x, baseline - 100)

  def draw_battery_chevrons(graph, -3, x, baseline),
    do:
      graph
      |> draw_chevron_down(x, baseline - 60)
      |> draw_chevron_down(x, baseline - 80)
      |> draw_chevron_down(x, baseline - 100)

  defp draw_chevron_up(graph, x, y) do
    chevron_w = 60
    chevron_h = 14
    x = x + @battery_w / 2 - chevron_w / 2

    graph
    |> path(
      [
        :begin,
        {:move_to, x, y},
        {:line_to, x + chevron_w / 2, y - chevron_h},
        {:line_to, x + chevron_w, y}
      ],
      stroke: {6, :white}
    )
  end

  defp draw_chevron_down(graph, x, y) do
    chevron_w = 60
    chevron_h = 14
    x = x + @battery_w / 2 - chevron_w / 2

    graph
    |> path(
      [
        :begin,
        {:move_to, x, y},
        {:line_to, x + chevron_w / 2, y + chevron_h},
        {:line_to, x + chevron_w, y}
      ],
      stroke: {6, :white}
    )
  end

  defp draw_thermometer(graph, name, pct, x, baseline) do
    pct = pct |> max(0) |> min(100)
    fill_h = round(pct / 100 * @therm_h)
    # fill_y = @therm_top_y + @therm_h - fill_h
    fill_y_start = baseline - fill_h

    graph
    |> rect(
      {@therm_w, @therm_h},
      fill: {30, 30, 50},
      stroke: {2, {80, 80, 150}},
      translate: {x, baseline - @therm_h}
    )
    |> draw_fill(pct, fill_h, fill_y_start, x)
    |> text(
      "#{round(pct)}%",
      font_size: @label_font_size,
      fill: :white,
      text_align: :center,
      translate: {x + @therm_w / 2, baseline + 18}
    )
    |> text(
      name,
      font_size: @label_font_size,
      fill: :white,
      text_align: :center,
      translate: {x + @therm_w / 2, baseline - @therm_h - 10}
    )
  end

  defp draw_fill(graph, _pct, 0, _fill_y, _x), do: graph

  defp draw_fill(graph, pct, fill_h, fill_y, x) do
    rect(graph, {@therm_w - 4, fill_h}, fill: fill_color(pct), translate: {x + 2, fill_y - 2})
  end

  defp season_time_remaining(%{upcoming_season: "temperate"}) do
    {100, 200, 100}
  end

  defp season_time_remaining(%{upcoming_season: "drought"}) do
    {200, 100, 200}
  end

  defp season_time_remaining(%{upcoming_season: "badtide"}) do
    {200, 100, 100}
  end

  defp fill_color(pct) when pct < 25, do: {200, 60, 60}
  defp fill_color(pct) when pct < 50, do: {200, 160, 60}
  defp fill_color(_pct), do: {60, 120, 220}
end
