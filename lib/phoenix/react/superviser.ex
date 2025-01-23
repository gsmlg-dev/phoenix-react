defmodule Phoenix.React.Superviser do
  use Supervisor

  def start_link(init_arg) do
    Supervisor.start_link(__MODULE__, init_arg, name: __MODULE__)
  end

  @impl true
  def init(_init_arg) do
    children = [
      {Task.Supervisor, name: Pohoenix.React.RenderTaskSupervisr},
      {Phoenix.React.Cache, []},
      {Phoenix.React.Server, []}
    ]

    Supervisor.init(children, strategy: :one_for_one)
  end
end
