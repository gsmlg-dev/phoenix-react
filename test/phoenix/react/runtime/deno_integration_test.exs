defmodule Phoenix.React.Runtime.DenoIntegrationTest do
  use ExUnit.Case, async: false

  alias Phoenix.React.Runtime.Deno

  describe "integration tests" do
    @describetag :integration

    test "config returns proper structure" do
      config = Deno.config()

      assert is_list(config)
      assert Keyword.has_key?(config, :cd)
      assert Keyword.has_key?(config, :cmd)
      assert Keyword.has_key?(config, :server_js)
      assert Keyword.has_key?(config, :port)
      assert Keyword.has_key?(config, :env)

      # Test default values
      assert is_binary(config[:cd])
      assert is_binary(config[:cmd]) or is_nil(config[:cmd])
      assert is_binary(config[:server_js])
      assert is_integer(config[:port])
      assert config[:port] > 0
      assert config[:env] in [:dev, :prod]
    end

    test "config respects application environment" do
      custom_config = [
        cmd: "/test/deno",
        server_js: "/test/server.js",
        port: 9999,
        env: :prod,
        cd: "/test/cd"
      ]

      Application.put_env(:phoenix_react_server, Deno, custom_config)

      try do
        config = Deno.config()
        assert config[:cmd] == "/test/deno"
        assert config[:server_js] == "/test/server.js"
        assert config[:port] == 9999
        assert config[:env] == :prod
        assert config[:cd] == "/test/cd"
      after
        Application.delete_env(:phoenix_react_server, Deno)
      end
    end

    test "get_rendered_component handles all render methods" do
      state = %Phoenix.React.Runtime{
        component_base: "/tmp/components",
        render_timeout: 5000,
        server_js: "/tmp/server.js",
        cd: "/tmp",
        runtime_port: nil
      }

      # Test all render methods return error when server is not running
      methods = [:render_to_string, :render_to_static_markup, :render_to_readable_stream]

      for method <- methods do
        result = Deno.get_rendered_component(method, "test_component", %{}, state)
        assert match?({:error, _}, result)
      end
    end

    test "runtime state structure is valid" do
      state = %Phoenix.React.Runtime{
        component_base: "/test/components",
        render_timeout: 30000,
        server_js: "/test/server.js",
        cd: "/test",
        runtime_port: nil
      }

      assert state.component_base == "/test/components"
      assert state.render_timeout == 30000
      assert state.server_js == "/test/server.js"
      assert state.cd == "/test"
      assert state.runtime_port == nil
    end
  end
end
