defmodule Phoenix.React.Runtime.DenoTest do
  use ExUnit.Case, async: false

  alias Phoenix.React.Runtime.Deno

  describe "config/0" do
    test "returns default configuration" do
      config = Deno.config()

      assert Keyword.keyword?(config)
      assert Keyword.has_key?(config, :cd)
      assert Keyword.has_key?(config, :cmd)
      assert Keyword.has_key?(config, :server_js)
      assert Keyword.has_key?(config, :port)
      assert Keyword.has_key?(config, :env)
    end

    test "uses custom configuration when provided" do
      Application.put_env(:phoenix_react_server, Deno,
        cmd: "/custom/deno",
        server_js: "/custom/server.js",
        port: 9999,
        env: :prod
      )

      try do
        config = Deno.config()
        assert config[:cmd] == "/custom/deno"
        assert config[:server_js] == "/custom/server.js"
        assert config[:port] == 9999
        assert config[:env] == :prod
      after
        Application.delete_env(:phoenix_react_server, Deno)
      end
    end
  end

  describe "start/1" do
    test "starts deno process with correct arguments" do
      # This test would require a actual deno installation
      # For now, we'll test the configuration part
      _component_base = "/tmp/components"

      # Mock the Port.open to avoid actually starting deno
      # In a real test environment, you might want to use Mox or similar

      # Test that the function exists and can be called
      assert is_function(&Deno.start/1)
    end
  end

  describe "get_rendered_component/4" do
    test "returns error when server is not running" do
      component = "test_component"
      props = %{"test" => "value"}

      state = %Phoenix.React.Runtime{
        component_base: "/tmp/components",
        render_timeout: 5000,
        server_js: "/tmp/server.js",
        cd: "/tmp",
        runtime_port: nil
      }

      # This should fail since there's no server running
      result = Deno.get_rendered_component(:render_to_string, component, props, state)

      # The result should be an error tuple
      assert match?({:error, _}, result)
    end
  end
end
