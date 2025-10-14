defmodule Phoenix.React.Monitoring do
  @moduledoc """
  Monitoring and metrics collection for Phoenix.React runtimes.

  This module provides:
  - Performance metrics collection
  - Health checks
  - Runtime status monitoring
  - Error tracking
  """

  require Logger

  @doc """
  Records a render request with timing information.
  """
  @spec record_render(String.t(), atom(), non_neg_integer(), :ok | :error) :: :ok
  def record_render(component, method, duration_ms, result) do
    metadata = %{
      component: component,
      method: method,
      duration_ms: duration_ms,
      result: result,
      timestamp: DateTime.utc_now()
    }

    Logger.debug("React render: #{inspect(metadata)}")

    # Could integrate with telemetry here
    :telemetry.execute([:phoenix, :react, :render], %{duration: duration_ms}, metadata)
  end

  @doc """
  Records a runtime startup event.
  """
  @spec record_runtime_startup(String.t(), non_neg_integer()) :: :ok
  def record_runtime_startup(runtime_name, port) do
    metadata = %{
      runtime: runtime_name,
      port: port,
      timestamp: DateTime.utc_now()
    }

    Logger.info("React runtime started: #{inspect(metadata)}")
    :telemetry.execute([:phoenix, :react, :runtime_startup], %{}, metadata)
  end

  @doc """
  Records a runtime shutdown event.
  """
  @spec record_runtime_shutdown(String.t(), term()) :: :ok
  def record_runtime_shutdown(runtime_name, reason) do
    metadata = %{
      runtime: runtime_name,
      reason: reason,
      timestamp: DateTime.utc_now()
    }

    Logger.info("React runtime shutdown: #{inspect(metadata)}")
    :telemetry.execute([:phoenix, :react, :runtime_shutdown], %{}, metadata)
  end

  @doc """
  Records a file change event.
  """
  @spec record_file_change(String.t(), String.t()) :: :ok
  def record_file_change(path, action \\ "changed") do
    metadata = %{
      path: path,
      action: action,
      timestamp: DateTime.utc_now()
    }

    Logger.debug("React file change: #{inspect(metadata)}")
    :telemetry.execute([:phoenix, :react, :file_change], %{}, metadata)
  end

  @doc """
  Records a build event.
  """
  @spec record_build(String.t(), non_neg_integer(), :ok | :error) :: :ok
  def record_build(runtime_name, duration_ms, result) do
    metadata = %{
      runtime: runtime_name,
      duration_ms: duration_ms,
      result: result,
      timestamp: DateTime.utc_now()
    }

    Logger.info("React build: #{inspect(metadata)}")
    :telemetry.execute([:phoenix, :react, :build], %{duration: duration_ms}, metadata)
  end

  @doc """
  Performs a health check on the runtime.
  """
  @spec health_check(String.t(), non_neg_integer()) :: {:ok, map()} | {:error, term()}
  def health_check(runtime_name, port) do
    start_time = System.monotonic_time(:millisecond)

    url = "http://localhost:#{port}/stop"

    case :httpc.request(:get, {String.to_charlist(url), []}, [], []) do
      {:ok, {{_version, status_code, _status_text}, _headers, _body}}
      when status_code in 200..299 ->
        duration = System.monotonic_time(:millisecond) - start_time

        metadata = %{
          runtime: runtime_name,
          port: port,
          status: "healthy",
          response_time_ms: duration,
          timestamp: DateTime.utc_now()
        }

        Logger.debug("React health check: #{inspect(metadata)}")
        {:ok, metadata}

      {:ok, {{_version, status_code, _status_text}, _headers, body}} ->
        duration = System.monotonic_time(:millisecond) - start_time
        error = "HTTP #{status_code}: #{body}"

        metadata = %{
          runtime: runtime_name,
          port: port,
          status: "unhealthy",
          error: error,
          response_time_ms: duration,
          timestamp: DateTime.utc_now()
        }

        Logger.warning("React health check failed: #{inspect(metadata)}")
        {:error, error}

      {:error, reason} ->
        duration = System.monotonic_time(:millisecond) - start_time

        metadata = %{
          runtime: runtime_name,
          port: port,
          status: "unreachable",
          error: reason,
          response_time_ms: duration,
          timestamp: DateTime.utc_now()
        }

        Logger.error("React health check failed: #{inspect(metadata)}")
        {:error, reason}
    end
  end

  @doc """
  Gets runtime statistics.
  """
  @spec get_runtime_stats(String.t()) :: map()
  def get_runtime_stats(runtime_name) do
    # This could be expanded to collect more detailed stats
    %{
      runtime: runtime_name,
      uptime: get_runtime_uptime(runtime_name),
      memory_usage: get_memory_usage(),
      process_count: length(Process.list()),
      timestamp: DateTime.utc_now()
    }
  end

  @doc """
  Measures execution time of a function and records it.
  """
  @spec measure(String.t(), atom(), function()) :: any()
  def measure(operation_name, telemetry_event, fun) when is_function(fun, 0) do
    start_time = System.monotonic_time(:millisecond)

    try do
      result = fun.()
      duration = System.monotonic_time(:millisecond) - start_time

      metadata = %{
        operation: operation_name,
        duration_ms: duration,
        result: :ok,
        timestamp: DateTime.utc_now()
      }

      Logger.debug("Operation measured: #{inspect(metadata)}")
      :telemetry.execute(telemetry_event, %{duration: duration}, metadata)

      result
    rescue
      error ->
        duration = System.monotonic_time(:millisecond) - start_time

        metadata = %{
          operation: operation_name,
          duration_ms: duration,
          result: :error,
          error: Exception.format(:error, error),
          timestamp: DateTime.utc_now()
        }

        Logger.error("Operation failed: #{inspect(metadata)}")
        :telemetry.execute(telemetry_event, %{duration: duration}, metadata)

        reraise error, __STACKTRACE__
    end
  end

  # Private helper functions

  defp get_runtime_uptime(_runtime_name) do
    # This would need to be implemented based on how we track startup time
    # For now, return a placeholder
    "unknown"
  end

  defp get_memory_usage do
    :erlang.memory()
  end
end
