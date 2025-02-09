
defmodule SystemStats do
  use GenServer

  def get_stats do
    GenServer.call(__MODULE__, :get_stats)
  end

  def start_link(_) do
    GenServer.start_link(__MODULE__, [], name: __MODULE__)
  end

  def init(state) do
    schedule_work()
    {:ok, state}
  end

  def handle_call(:get_stats, _from, state) do
    {:reply, state, state}
  end

  def handle_info(:check_stats, state) do
    cpu = cpu_usage()
    mem = memory_usage()
    time = DateTime.utc_now()
    # time = :calendar.local_time |> elem(1) |> fn({hour, minute, second}) ->
    #   h = if hour < 10, do: "0#{hour}", else: "#{hour}"
    #   m = if minute < 10, do: "0#{minute}", else: "#{minute}"
    #   s = if second < 10, do: "0#{second}", else: "#{second}"
    #   "#{h}:#{m}:#{s}"
    # end.()
    schedule_work()
    ReactDemoWeb.Endpoint.broadcast("system_usage:lobby", "stats", %{date: time, cpu: cpu, mem: mem})

    {:noreply, [{time, cpu, mem} | state] |> Enum.take(100)}
  end

  defp schedule_work do
    Process.send_after(self(), :check_stats, 5000)  # Every 5 seconds
  end

  def cpu_usage do
    :cpu_sup.util()
  end

  def memory_usage() do
    total = :memsup.get_system_memory_data[:total_memory]
    available = :memsup.get_system_memory_data[:available_memory]
    used = total - available
    used / 1024 / 1024
  end
end
