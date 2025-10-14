defmodule Phoenix.React.Config do
  @moduledoc """
  Centralized configuration management for Phoenix.React runtimes.

  This module provides default values and validation for all configurable
  parameters across different runtime implementations.
  """

  @doc """
  Default configuration values for all runtimes.
  """
  def defaults do
    %{
      # Common defaults
      env: :dev,
      render_timeout: 5000,
      cache_ttl: 60,

      # Bun-specific defaults
      bun: %{
        port: 5225,
        server_js: "bun/server.js",
        cmd: "bun"
      },

      # Deno-specific defaults
      deno: %{
        port: 5226,
        server_js: "deno/server.js",
        cmd: "deno",
        write_dirs: ["/tmp", "/var/tmp"],
        parent_check_interval: 5000,
        node_modules_dir: true
      },

      # File watching defaults
      file_watcher: %{
        throttle_ms: 3000,
        debounce_ms: 100
      },

      # Security defaults
      security: %{
        max_component_name_length: 100,
        allowed_component_name_pattern: ~r/^[a-zA-Z0-9_-]+$/,
        # 1MB
        max_request_size: 1_048_576,
        request_timeout_ms: 30000
      }
    }
  end

  @doc """
  Gets configuration for a specific runtime with defaults applied.
  """
  def runtime_config(runtime_name, user_config \\ %{}) do
    runtime_defaults = Map.get(defaults(), runtime_name, %{})
    common_defaults = Map.delete(defaults(), runtime_name)

    merged =
      common_defaults
      |> Map.merge(runtime_defaults)
      |> Map.merge(user_config)

    validate_runtime_config(runtime_name, merged)
  end

  @doc """
  Validates runtime-specific configuration.
  """
  def validate_runtime_config(runtime_name, config) when is_map(config) do
    errors =
      []
      |> then(&validate_port(&1, config[:port]))
      |> then(&validate_env(&1, config[:env]))
      |> then(&validate_timeout(&1, config[:render_timeout]))
      |> then(&validate_write_dirs(&1, config[:write_dirs], runtime_name))
      |> then(&validate_parent_check_interval(&1, config[:parent_check_interval], runtime_name))

    if Enum.empty?(errors) do
      {:ok, config}
    else
      {:error,
       "#{String.upcase(Atom.to_string(runtime_name))} configuration errors: #{Enum.join(errors, "; ")}"}
    end
  end

  @doc """
  Gets security configuration.
  """
  def security_config(overrides \\ %{}) do
    defaults().security
    |> Map.merge(overrides)
  end

  @doc """
  Gets file watcher configuration.
  """
  def file_watcher_config(overrides \\ %{}) do
    defaults().file_watcher
    |> Map.merge(overrides)
  end

  # Private validation functions

  defp validate_port(errors, nil), do: ["port is required" | errors]

  defp validate_port(errors, port) when is_integer(port) and port > 0 and port <= 65535,
    do: errors

  defp validate_port(errors, _), do: ["port must be between 1 and 65535" | errors]

  defp validate_env(errors, nil), do: ["env is required" | errors]
  defp validate_env(errors, env) when env in [:dev, :prod], do: errors
  defp validate_env(errors, _), do: ["env must be :dev or :prod" | errors]

  defp validate_timeout(errors, nil), do: errors
  defp validate_timeout(errors, timeout) when is_integer(timeout) and timeout > 0, do: errors
  defp validate_timeout(errors, _), do: ["render_timeout must be a positive integer" | errors]

  defp validate_write_dirs(errors, nil, :deno),
    do: ["write_dirs is required for Deno runtime" | errors]

  defp validate_write_dirs(errors, dirs, :deno) when is_list(dirs) and length(dirs) > 0,
    do: errors

  defp validate_write_dirs(errors, _, :deno),
    do: ["write_dirs must be a non-empty list for Deno runtime" | errors]

  defp validate_write_dirs(errors, _, _), do: errors

  defp validate_parent_check_interval(errors, nil, :deno),
    do: ["parent_check_interval is required for Deno runtime" | errors]

  defp validate_parent_check_interval(errors, interval, :deno)
       when is_integer(interval) and interval >= 1000,
       do: errors

  defp validate_parent_check_interval(errors, _, :deno),
    do: ["parent_check_interval must be at least 1000ms for Deno runtime" | errors]

  defp validate_parent_check_interval(errors, _, _), do: errors

  @doc """
  Converts configuration to keyword list for backward compatibility.
  """
  def to_keyword_list(config) when is_map(config) do
    config
    |> Enum.map(fn {k, v} -> {k, v} end)
  end
end
