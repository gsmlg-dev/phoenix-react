defmodule Phoenix.React.Runtime.Common do
  @moduledoc """
  Common functionality shared between different runtime implementations (Bun, Deno, etc.).

  This module provides shared behavior for:
  - Port management and cleanup
  - HTTP client operations
  - Configuration handling
  - Error handling patterns
  - Process monitoring
  """

  require Logger

  @doc """
  Standardized error handling for runtime operations.

  Returns {:ok, result} or {:error, reason} tuples consistently.
  """
  @spec handle_result(term()) :: {:ok, term()} | {:error, String.t()}
  def handle_result({:ok, result}), do: {:ok, result}
  def handle_result({:error, reason}), do: {:error, format_error(reason)}
  def handle_result(result), do: {:ok, result}

  @doc """
  Formats error messages consistently across runtimes.
  """
  @spec format_error(term()) :: String.t()
  def format_error(reason) when is_binary(reason), do: reason
  def format_error(reason), do: inspect(reason)

  @doc """
  Makes HTTP request to runtime server with standardized error handling.
  """
  def make_http_request(server_port, method, component, props, timeout) do
    url = "http://localhost:#{server_port}/#{method}/#{component}"
    headers = [{~c"Content-Type", ~c"application/json"}]
    body = Jason.encode!(props)

    case :httpc.request(
           :post,
           {String.to_charlist(url), headers, ~c"application/json", String.to_charlist(body)},
           [timeout: timeout, connect_timeout: timeout],
           body_format: :binary
         ) do
      {:ok, {{_version, status_code, _status_text}, _headers, body}}
      when status_code in 200..299 ->
        {:ok, to_string(body)}

      {:ok, {{_version, status_code, _status_text}, _headers, body}} ->
        {:error, "HTTP #{status_code}\n\n#{body}"}

      {:error, reason} ->
        {:error, "HTTP request failed: #{format_error(reason)}"}
    end
  end

  @doc """
  Safely terminates a runtime process with proper cleanup.
  """
  @spec cleanup_runtime_process(port(), term()) :: term()
  def cleanup_runtime_process(runtime_port, reason) do
    case runtime_port |> Port.info(:os_pid) do
      {:os_pid, pid} when is_integer(pid) and pid > 0 ->
        Logger.debug("Terminating runtime process with PID: #{pid}")
        System.cmd("kill", ["-TERM", "#{pid}"])

        # Give process time to terminate gracefully
        Process.sleep(100)

        # Force kill if still running
        case System.cmd("kill", ["-0", "#{pid}"]) do
          {_, 0} ->
            System.cmd("kill", ["-9", "#{pid}"])
            Logger.warning("Force killed runtime process with PID: #{pid}")

          _ ->
            :ok
        end

      {:os_pid, pid} ->
        Logger.warning("Invalid PID found: #{pid}")

      _ ->
        Logger.debug("No runtime process to cleanup")
    end

    normalize_exit_reason(reason)
  end

  @doc """
  Normalizes exit reasons for consistent process termination.
  """
  @spec normalize_exit_reason(term()) :: term()
  def normalize_exit_reason(:normal), do: :normal
  def normalize_exit_reason(:shutdown), do: :shutdown
  def normalize_exit_reason({:shutdown, _} = reason), do: reason
  def normalize_exit_reason(reason), do: {:shutdown, reason}

  @doc """
  Gets OS PID from port with error handling.
  """
  @spec get_port_os_pid(port()) :: integer() | nil
  def get_port_os_pid(runtime_port) do
    case runtime_port |> Port.info(:os_pid) do
      {:os_pid, pid} when is_integer(pid) -> pid
      _ -> nil
    end
  end

  @doc """
  Creates port options for spawning runtime processes.
  """
  @spec port_options(String.t(), [String.t()], keyword()) :: keyword()
  def port_options(_executable, args, opts \\ []) do
    default_opts = [
      {:args, args},
      :stream,
      :binary,
      :exit_status,
      :use_stdio,
      :stderr_to_stdout
    ]

    custom_opts =
      if cd = opts[:cd] do
        [{:cd, cd}]
      else
        []
      end

    env_opts =
      if env = opts[:env] do
        [{:env, env}]
      else
        []
      end

    default_opts ++ custom_opts ++ env_opts
  end

  @doc """
  Creates environment variables for runtime processes.
  """
  @spec runtime_env(String.t(), String.t(), String.t(), String.t()) :: [{charlist(), charlist()}]
  def runtime_env(port_var, port_value, env_var, env_value) do
    [
      {~c"PORT", String.to_charlist(port_value)},
      {String.to_charlist(port_var), String.to_charlist(port_value)},
      {String.to_charlist(env_var), String.to_charlist(env_value)},
      {~c"COMPONENT_BASE", String.to_charlist(env_value)}
    ]
  end

  @doc """
  Handles file change events with async processing and timeout.
  Uses non-blocking approach to prevent GenServer blocking.
  """
  @spec handle_file_change(String.t(), module(), keyword(), timeout()) :: :ok | {:error, term()}
  def handle_file_change(path, bundle_module, bundle_args, _timeout \\ 5000) do
    Logger.debug("Component base changed: #{path}, rebuilding...")

    # For now, always return :ok since we're handling errors asynchronously
    # In a future version, we could implement proper error tracking
    Task.start(fn ->
      try do
        apply(bundle_module, :run, bundle_args)
        Logger.debug("Component base rebuilt: #{path}")
      rescue
        error ->
          Logger.error("Failed to rebuild components: #{format_error(error)}")
      catch
        :throw, error ->
          Logger.error("Build failed: #{format_error(error)}")
      end
    end)

    # Return immediately, don't block the GenServer
    :ok
  end

  @doc """
  Validates configuration values with proper error messages.
  """
  @spec validate_config(keyword(), atom()) :: {:ok, keyword()} | {:error, String.t()}
  def validate_config(config, runtime_name) do
    cond do
      not Keyword.has_key?(config, :cmd) ->
        {:error, "#{runtime_name}: :cmd is required in configuration"}

      not Keyword.has_key?(config, :port) ->
        {:error, "#{runtime_name}: :port is required in configuration"}

      config[:port] <= 0 or config[:port] > 65535 ->
        {:error, "#{runtime_name}: :port must be between 1 and 65535"}

      config[:env] not in [:dev, :prod] ->
        {:error, "#{runtime_name}: :env must be :dev or :prod"}

      true ->
        {:ok, config}
    end
  end

  @doc """
  Merges user configuration with defaults, applying validation.
  """
  @spec merge_config(keyword(), keyword(), atom()) :: {:ok, keyword()} | {:error, String.t()}
  def merge_config(user_config, defaults, runtime_name) do
    config = Keyword.merge(defaults, user_config)
    validate_config(config, runtime_name)
  end
end
