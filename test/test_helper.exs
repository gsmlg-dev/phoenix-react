# Configure ExUnit to skip Deno tests if Deno is not available
exclude =
  if System.find_executable("deno") == nil do
    [:skip_if_no_deno]
  else
    []
  end

ExUnit.start(exclude: exclude)
Phoenix.React.start_link([])

ExUnit.after_suite(fn _results ->
  try do
    IO.puts("Stopping runtime ...")

    Phoenix.React.stop_runtime()

    :ok
  rescue
    _ -> :ok
  catch
    _ -> :ok
  end
end)
