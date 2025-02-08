ExUnit.start()
Phoenix.React.start_link([])
ExUnit.after_suite(fn _results ->
  IO.puts("Stopping runtime ...")

  Phoenix.React.stop_runtime()

  :ok
end)
