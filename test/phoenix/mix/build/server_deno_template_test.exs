defmodule Mix.Tasks.Phx.React.Deno.ServerTemplateTest do
  use ExUnit.Case, async: true

  describe "server_deno.js.eex template" do
    test "template compiles correctly with sample files" do
      files = [
        {"component1", "/path/to/component1.js"},
        {"component2", "/path/to/component2.js"}
      ]

      base_dir = "/test/components"

      # Read and compile the template
      template_path = Path.expand("../../../../lib/phoenix/mix/build/server_deno.js.eex", __DIR__)
      quoted = EEx.compile_file(template_path)

      # Evaluate the template
      {result, _bindings} = Code.eval_quoted(quoted, files: files, base_dir: base_dir)

      # Check that the result contains expected imports
      assert String.contains?(
               result,
               "import { Component as __component_0 } from \"/path/to/component1.js\""
             )

      assert String.contains?(
               result,
               "import { Component as __component_1 } from \"/path/to/component2.js\""
             )

      # Check that component mapping is created
      assert String.contains?(result, "__comMap[\"component1\"] = __component_0")
      assert String.contains?(result, "__comMap[\"component2\"] = __component_1")

      # Check that Deno-specific imports are present
      assert String.contains?(result, "import { serve } from \"https://deno.land/std")

      assert String.contains?(
               result,
               "import { renderToReadableStream, renderToString, renderToStaticMarkup } from \"npm:react-dom/server\""
             )

      # Check that environment variables are used
      assert String.contains?(result, "DENO_ENV")
      assert String.contains?(result, "COMPONENT_BASE")

      # Check that server setup is present
      assert String.contains?(result, "await serve")
      assert String.contains?(result, "Deno.addSignalListener")
    end

    test "template handles empty files list" do
      files = []
      base_dir = "/test/components"

      template_path = Path.expand("../../../../lib/phoenix/mix/build/server_deno.js.eex", __DIR__)
      quoted = EEx.compile_file(template_path)

      {result, _bindings} = Code.eval_quoted(quoted, files: files, base_dir: base_dir)

      # Should still contain the basic structure
      assert String.contains?(result, "const __comMap = {};")
      assert String.contains?(result, "import { serve } from")
      assert String.contains?(result, "await serve")
    end
  end
end
