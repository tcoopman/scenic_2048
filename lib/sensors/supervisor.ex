# a simple supervisor that starts up the Scenic.SensorPubSub server
# and any set of other sensor processes

defmodule Scenic2048.Sensor.Supervisor do
  use Supervisor

  def start_link() do
    Supervisor.start_link(__MODULE__, :ok)
  end

  def init(:ok) do
    children = []

    Supervisor.init(children, strategy: :one_for_one)
  end
end
