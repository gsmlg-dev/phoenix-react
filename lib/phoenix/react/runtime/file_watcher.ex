defmodule Phoenix.React.Runtime.FileWatcher do
  @moduledoc false
  require Logger

  use GenServer

  def set_ref(ref) do
    GenServer.cast(__MODULE__, {:set_ref, ref})
  end

  def start_link(args) do
    GenServer.start_link(__MODULE__, args, name: __MODULE__)
  end

  @impl true
  def init(args) do
    path = Keyword.fetch!(args, :path)
    {:ok, watcher_pid} = FileSystem.start_link(dirs: [path])
    FileSystem.subscribe(watcher_pid)
    IO.puts("Watching #{path} for changes...")

    {:ok,
     args
     |> Keyword.put(:watcher_pid, watcher_pid)
     |> Keyword.put(:update_time, System.os_time(:second))}
  end

  @impl true
  def handle_cast({:set_ref, ref}, state) do
    {:noreply, state |> Keyword.put(:ref, ref)}
  end

  @impl true
  def handle_info({:file_event, _watcher_pid, {path, [:modified, :closed]}}, state) do
    IO.puts("File changed: #{path} - Events: [:modified, :closed]")
    send(self(), {:throttle_update, path})
    {:noreply, state}
  end

  def handle_info({:file_event, _watcher_pid, {_path, _events}}, state) do
    # ref = Keyword.fetch!(state, :ref)
    # IO.puts("File changed: #{path} - Events: #{inspect(events)}")
    # send(self(), {:throttle_update, path, events})
    {:noreply, state}
  end

  def handle_info({:throttle_update, path}, state) do
    IO.inspect(state)
    update_time = Keyword.fetch!(state, :update_time)
    now = System.os_time(:second)
    will_update = now > update_time

    Logger.debug(
      ~s[Throttle update #{update_time} / #{now}, #{if(will_update, do: "will update", else: "skip update")}]
    )

    if now > update_time do
      Process.send_after(state[:ref], {:component_base_changed, path}, 3_000)
      {:noreply, state |> Keyword.put(:update_time, now + 3)}
    else
      {:noreply, state}
    end
  end
end
