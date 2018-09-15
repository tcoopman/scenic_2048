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
  @all_positions for(i <- 1..@dimensions, j <- 1..@dimensions, do: {i, j})
  @background_color {:color, {184, 173, 162, 255}}
  @font_color {:color, {119, 110, 101}}
  # calculated via `Scenic.Cache.Hash.compute(File.read!("./ClearSans-Medium.ttf"), :sha)`
  @font_hash "cu1h9EqFbnBMyCyDDqtWtMh2lOw"
  @font_path :code.priv_dir(:scenic_2048)
             |> Path.join("/static/fonts/ClearSans-Medium.ttf")

  def init(_, _opts) do
    Scenic.Cache.File.load(@font_path, @font_hash) |> IO.inspect()
    board_state = initial_state()

    graph =
      Graph.build(font: @font_hash, font_size: 24)
      |> group(
        fn g ->
          g
          |> rrect({900, 900, 6}, fill: @background_color, t: {@x_offset, @y_offset})
          |> group(
            fn g ->
              g |> empty_board()
            end,
            id: :board
          )
        end,
        t: {0, 0}
      )
      |> update_board(board_state)

    push_graph(graph)

    {:ok, %{graph: graph, board_state: board_state}}
  end

  def handle_input({:key, {key, :release, _}}, _context, state)
      when key == "left" or key == "right" or key == "up" or key == "down" do
    state = update_state(key, state)
    update_board(state.graph, state.board_state) |> push_graph
    {:noreply, state}
  end

  def handle_input(_, _context, state), do: {:noreply, state}

  defp initial_state() do
    empty_blocks = for(i <- 1..@dimensions, j <- 1..@dimensions, do: {i, j}) |> Enum.shuffle()

    %{empty_blocks: empty_blocks, blocks: %{}}
    |> update_board_state()
    |> update_board_state()
  end

  defp update_state(_key, state) do
    %{board_state: %{empty_blocks: empty_blocks, blocks: blocks}, graph: graph} = state

    board_state =
      update_board_state(state.board_state)
      |> IO.inspect()

    %{board_state: board_state, graph: graph}
  end

  defp update_board(graph, %{blocks: blocks}) do
    @all_positions
    |> Enum.reduce(graph, fn {x, y}, graph ->
      number = Map.get(blocks, {x, y}, 0)

      number_text =
        case number do
          0 -> ""
          number -> "#{number}"
        end

      graph
      |> Graph.modify(block_id(x, y), &update_opts(&1, fill: block_color(number)))
      |> Graph.modify(block_text_id(x, y), &text(&1, number_text))
    end)
  end

  defp empty_board(g) do
    @all_positions
    |> Enum.reduce(g, fn {x, y}, g ->
      x_pos = @x_offset + @padding_side + (@block_size + @padding) * (x - 1)
      y_pos = @y_offset + @padding_side + (@block_size + @padding) * (y - 1)

      g
      |> rrect({@block_size, @block_size, 6},
        fill: block_color(0),
        t: {x_pos, y_pos},
        id: block_id(x, y)
      )
      |> text("",
        translate: {
          x_pos + @block_size / 2,
          y_pos + @block_size / 2
        },
        fill: @font_color,
        font_size: 120,
        text_align: :center_middle,
        id: block_text_id(x, y)
      )
    end)
  end

  defp random_block_number() do
    if :rand.uniform(10) < 8 do
      2
    else
      4
    end
  end

  defp block_id(x, y), do: :"block-#{x}-#{y}"
  defp block_text_id(x, y), do: :"block-text-#{x}-#{y}"

  defp update_board_state(%{empty_blocks: []} = x), do: x

  defp update_board_state(%{empty_blocks: empty_blocks, blocks: blocks}) do
    [pos | empty_blocks] = empty_blocks

    blocks =
      blocks
      |> Map.put(pos, random_block_number())

    %{empty_blocks: empty_blocks, blocks: blocks}
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
