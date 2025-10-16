defmodule Phoenix.React.RuntimeIntegrationTest do
  use ExUnit.Case, async: false

  alias Phoenix.React.Runtime.Bun
  alias Phoenix.React.Runtime.Deno
  alias Phoenix.React.Config

  @moduletag :integration

  setup do
    # Clean up any existing runtimes before each test
    on_exit(fn ->
      # Give processes time to clean up
      Process.sleep(100)
    end)

    :ok
  end

  describe "Bun Runtime Integration" do
    @describetag :bun_runtime

    test "configuration validation" do
      # Test valid configuration
      valid_config = [
        cmd: "bun",
        port: 5225,
        env: :dev,
        cd: File.cwd!()
      ]

      assert {:ok, config} = Config.runtime_config(:bun, Enum.into(valid_config, %{}))
      assert config.cmd == "bun"
      assert config.port == 5225
      assert config.env == :dev

      # Test invalid configuration
      invalid_config = [
        cmd: "bun",
        # Invalid port
        port: 70000,
        env: :dev
      ]

      assert {:error, _} = Config.runtime_config(:bun, Enum.into(invalid_config, %{}))
    end

    test "runtime startup and shutdown" do
      # Skip if bun is not available
      unless System.find_executable("bun") do
        flunk("Bun not available for integration testing")
      end

      # Try multiple times to find an available port
      {_test_port, pid} =
        Enum.reduce_while(1..5, nil, fn _attempt, _acc ->
          test_port = 15225 + :rand.uniform(1000)

          Application.put_env(:phoenix_react_server, Bun,
            cmd: System.find_executable("bun"),
            port: test_port,
            env: :dev,
            cd: File.cwd!()
          )

          # Start the runtime without name registration
          case GenServer.start_link(Bun, component_base: "test/fixtures", render_timeout: 5000) do
            {:ok, pid} ->
              # Give it time to start
              Process.sleep(2000)

              if Process.alive?(pid) do
                {:halt, {test_port, pid}}
              else
                # Process died, try another port
                {:cont, nil}
              end

            {:error, _reason} ->
              # Failed to start, try another port
              {:cont, nil}
          end
        end)

      # If we couldn't find a working port, fail the test
      if pid == nil do
        flunk("Could not start Bun runtime after 5 attempts")
      end

      # Verify it's running
      assert Process.alive?(pid)

      # Stop the runtime
      GenServer.stop(pid, :normal)

      # Verify it's stopped
      refute Process.alive?(pid)
    end
  end

  describe "Deno Runtime Integration" do
    @describetag :deno_runtime
    @describetag :skip_if_no_deno

    test "configuration validation" do
      # Test valid configuration
      valid_config = %{
        cmd: "deno",
        port: 5226,
        env: :dev,
        write_dirs: ["/tmp"],
        parent_check_interval: 5000
      }

      assert {:ok, config} = Config.runtime_config(:deno, valid_config)
      assert config.cmd == "deno"
      assert config.port == 5226
      assert config.write_dirs == ["/tmp"]

      # Test invalid configuration
      invalid_config = %{
        cmd: "deno",
        # Invalid port
        port: 70000,
        env: :dev,
        # Empty write_dirs
        write_dirs: []
      }

      assert {:error, _} = Config.runtime_config(:deno, invalid_config)
    end

    @tag :skip_if_no_deno
    test "runtime startup and shutdown" do
      # Skip if deno is not available - this is handled by the setup below

      # Configure test environment with unique port
      test_port = 15227 + :rand.uniform(1000)

      Application.put_env(:phoenix_react_server, Deno,
        cmd: System.find_executable("deno"),
        port: test_port,
        env: :dev,
        cd: File.cwd!(),
        write_dirs: ["/tmp"],
        parent_check_interval: 2000
      )

      # Start the runtime
      {:ok, pid} = Deno.start_link(component_base: "test/fixtures", render_timeout: 5000)

      # Give it time to start
      Process.sleep(3000)

      # Verify it's running
      assert Process.alive?(pid)

      # Stop the runtime
      GenServer.stop(pid, :normal)

      # Verify it's stopped
      refute Process.alive?(pid)
    end
  end

  describe "Common Functionality" do
    test "security configuration validation" do
      security_config = Config.security_config()

      assert security_config.max_component_name_length == 100
      assert is_struct(security_config.allowed_component_name_pattern, Regex)
      assert security_config.max_request_size == 1_048_576
      assert security_config.request_timeout_ms == 30000
    end

    test "file watcher configuration validation" do
      watcher_config = Config.file_watcher_config()

      assert watcher_config.throttle_ms == 3000
      assert watcher_config.debounce_ms == 100
    end

    test "monitoring functionality" do
      # Test monitoring functions don't crash
      assert :ok = Phoenix.React.Monitoring.record_render("test", :render_to_string, 100, :ok)
      assert :ok = Phoenix.React.Monitoring.record_runtime_startup("test", 5225)
      assert :ok = Phoenix.React.Monitoring.record_runtime_shutdown("test", :normal)
      assert :ok = Phoenix.React.Monitoring.record_file_change("/test/path", "changed")
      assert :ok = Phoenix.React.Monitoring.record_build("test", 1000, :ok)

      # Test measurement function
      result =
        Phoenix.React.Monitoring.measure("test_op", [:test], fn ->
          Process.sleep(10)
          :test_result
        end)

      assert result == :test_result

      # Test runtime stats
      stats = Phoenix.React.Monitoring.get_runtime_stats("test")
      assert is_map(stats)
      assert stats.runtime == "test"
    end
  end

  describe "Error Handling" do
    test "invalid component names are rejected" do
      # This would be tested through the actual HTTP requests to the runtime servers
      # For now, we test the validation logic
      security_config = Config.security_config()
      pattern = security_config.allowed_component_name_pattern

      # Valid names
      assert "valid_component" =~ pattern
      assert "valid-component-123" =~ pattern

      # Invalid names
      refute "../../../etc/passwd" =~ pattern
      refute "component<script>" =~ pattern
      refute "component with spaces" =~ pattern
    end

    test "configuration errors are properly formatted" do
      {:error, error_msg} = Config.runtime_config(:bun, %{port: 70000})
      assert is_binary(error_msg)
      assert error_msg =~ "configuration errors"
    end
  end
end
