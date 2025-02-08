ExUnit.start()
Phoenix.React.start_link([])

ExUnit.after_suite(fn _results ->
  try do
    IO.puts("Stopping runtime ...")

    Phoenix.React.stop_runtime()

    :ok
  rescue
    _ -> :ok
  end
end)
