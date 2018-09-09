defmodule Scenic2048.Scene.Game2048 do
  @moduledoc """
  Sample scene.
  """

  use Scenic.Scene
  alias Scenic.Graph
  import Scenic.Primitives

  @block_size 200
  @padding 20
  @padding_side 20
  @x_offset 50
  @y_offset 50
  @dimensions 4
  @background_color {:color, {184, 173, 162, 255}}
  @font_color {:color, {119, 110, 101}}
  # calculated via `Scenic.Cache.Hash.compute(File.read!("./ClearSans-Medium.ttf"), :sha)`
  @font_hash "cu1h9EqFbnBMyCyDDqtWtMh2lOw"
  @font_path  :code.priv_dir(:scenic_2048)
              |> Path.join( "/static/fonts/ClearSans-Medium.ttf" )

  @color_2 {:color, {203, 193, 181, 255}}

  @all_colors [
    {:color, {203, 193, 181, 255}},
    {:color, {236, 228, 219, 255}},
    {:color, {235, 225, 203, 255}},
    {:color, {232, 180, 130, 255}},
    {:color, {227, 153, 103, 255}},
    {:color, {223, 129, 101, 255}},
    {:color, {246, 94, 59, 255}},
    {:color, {237, 207, 114, 255}},
    {:color, {237, 204, 97, 255}},
    {:color, {237, 200, 80, 255}},
    {:color, {237, 197, 63, 255}},
    {:color, {237, 194, 46, 255}},
    {:color, {60, 58, 50, 255}}
  ]

  def init(_, _opts) do
    # Scenic.Cache.File.load(@font_path, @font_hash) |> IO.inspect()
    state = initial_state() |> IO.inspect()

    graph =
      Graph.build(font: :roboto_mono, font_size: 24)
      |> group(
        fn g ->
          g
          |> rrect({900, 900, 6}, fill: @background_color, t: {@x_offset, @y_offset})
          |> build_board(state)
        end,
        t: {0, 0}
      )

    push_graph(graph)

    {:ok, graph}
  end

  defp initial_state() do
    empty_blocks = for(i <- 1..@dimensions, j <- 1..@dimensions, do: {i, j}) |> Enum.shuffle()
    [pos1 | [pos2 | empty_blocks]] = empty_blocks

    blocks =
      %{}
      |> Map.put(pos1, random_block_number())
      |> Map.put(pos2, random_block_number())

    %{
      empty_blocks: empty_blocks,
      blocks: blocks
    }
  end

  defp build_board(g, %{blocks: blocks}) do
    all_positions = for(i <- 1..@dimensions, j <- 1..@dimensions, do: {i, j})

    all_positions
    |> Enum.reduce(g, fn {x, y}, g ->
      x_pos = @x_offset + @padding_side + (@block_size + @padding) * (x - 1)
      y_pos = @y_offset + @padding_side + (@block_size + @padding) * (y - 1)

      number = Map.get(blocks, {x, y}, 0)

      color = block_color(number)

      g =
        g
        |> rrect({@block_size, @block_size, 6},
          fill: color,
          t: {x_pos, y_pos}
        )

      case number do
        0 ->
          g

        number ->
          g
          |> text("#{number}",
            translate: {
              x_pos + @block_size / 2,
              y_pos + @block_size / 2
            },
            fill: @font_color,
            font_size: 120,
            text_align: :center_middle
          )
      end
    end)
  end

  defp random_block_number() do
    if :rand.uniform(10) < 7 do
      2
    else
      4
    end
  end

  defp block_color(0), do: {:color, {203, 193, 181, 255}}
  defp block_color(2), do: {:color, {236, 228, 219, 255}}
  defp block_color(4), do: {:color, {235, 225, 203, 255}}
  defp block_color(8), do: {:color, {232, 180, 130, 255}}
  defp block_color(16), do: {:color, {227, 153, 103, 255}}
  defp block_color(32), do: {:color, {223, 129, 101, 255}}
  defp block_color(64), do: {:color, {246, 94, 59, 255}}
  defp block_color(128), do: {:color, {237, 207, 114, 255}}
  defp block_color(256), do: {:color, {237, 204, 97, 255}}
  defp block_color(512), do: {:color, {237, 200, 80, 255}}
  defp block_color(1024), do: {:color, {237, 197, 63, 255}}
  defp block_color(2048), do: {:color, {237, 194, 46, 255}}
  # defp block_color(nil), do: {:color, {60, 58, 50, 255}
end
