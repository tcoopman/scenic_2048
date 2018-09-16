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
    Scenic.Cache.File.load(@font_path, @font_hash)
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
    key = String.to_atom(key)
    state = update_state(key, state)
    update_board(state.graph, state.board_state) |> push_graph
    {:noreply, state}
  end

  def handle_input(_, _context, state), do: {:noreply, state}

  defp initial_state() do
    %{}
    |> update_board_state()
    |> update_board_state()
  end

  defp update_state(key, state) do
    %{board_state: board_state, graph: graph} = state

    board_state =
      board_state
      |> reduce(key)
      |> update_board_state()

    %{board_state: board_state, graph: graph}
  end

  defp update_board(graph, board_state) do
    @all_positions
    |> Enum.reduce(graph, fn {x, y}, graph ->
      number = Map.get(board_state, {x, y}, 0)

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

  defp reduce(board_state, key) do
    key
    |> positions()
    |> Enum.with_index(1)
    |> Enum.flat_map(fn {row, i} ->
      Enum.map(row, fn pos ->
        {Map.get(board_state, pos, 0), pos}
      end)
      |> Enum.reject(&match?({0, _}, &1))
      |> squish([])
      |> to_position(key, i)
    end)
    |> Map.new()
  end

  defp positions(key) do
    for i <- 1..@dimensions, do: for(j <- indices(key), do: to_tupple(key, i, j))
  end

  defp to_position(numbers, key, i) do
    Enum.zip(numbers, indices(key))
    |> Enum.map(fn {number, index} ->
      {to_tupple(key, i, index), number}
    end)
  end

  defp indices(key) when key == :left or key == :up, do: for(i <- 1..@dimensions, do: i)
  defp indices(key) when key == :right or key == :down, do: for(i <- @dimensions..1, do: i)
  defp to_tupple(key, i, j) when key == :left or key == :right, do: {j, i}
  defp to_tupple(key, i, j) when key == :up or key == :down, do: {i, j}

  defp squish(numbers, result) do
    case numbers do
      [] -> result |> Enum.reverse()
      [{a, _}] -> squish([], [a | result])
      [{a, _}, {b, _} | tl] when a == b -> squish(tl, [a + b | result])
      [{a, _}, b | tl] when a != b -> squish([b | tl], [a | result])
    end
  end

  defp block_id(x, y), do: :"block-#{x}-#{y}"
  defp block_text_id(x, y), do: :"block-text-#{x}-#{y}"

  defp update_board_state(board_state) do
    empty_blocks = empty_blocks(board_state)

    case empty_blocks do
      [] ->
        board_state

      empty_blocks ->
        random_position = Enum.random(empty_blocks)
        Map.put(board_state, random_position, random_block_number())
    end
  end

  defp empty_blocks(board_state) do
    Enum.reject(@all_positions, fn pos ->
      Map.has_key?(board_state, pos)
    end)
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
