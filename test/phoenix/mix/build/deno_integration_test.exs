defmodule Mix.Tasks.Phx.React.Deno.BundleIntegrationTest do
  use ExUnit.Case, async: false

  alias Mix.Tasks.Phx.React.Deno.Bundle

  describe "bundle integration tests" do
    @describetag :integration

    test "find_files handles complex directory structures" do
      tmp_dir = System.tmp_dir!()
      test_dir = Path.join(tmp_dir, "deno_bundle_test_#{System.unique_integer()}")

      # Create complex directory structure
      File.mkdir_p!(test_dir)
      File.mkdir_p!(Path.join([test_dir, "components"]))
      File.mkdir_p!(Path.join([test_dir, "components", "ui"]))
      File.mkdir_p!(Path.join([test_dir, "utils"]))

      # Create various files
      files = [
        {"component1.js", "export const Component = () => null;"},
        {"components/component2.js", "export const Component = () => null;"},
        {"components/ui/button.js", "export const Component = () => null;"},
        {"utils/helper.js", "export const helper = () => null;"},
        {"README.md", "# Documentation"}
      ]

      for {path, content} <- files do
        path_parts = [test_dir | String.split(path, "/")]
        full_path = Path.join(path_parts)
        File.mkdir_p!(Path.dirname(full_path))
        File.write!(full_path, content)
      end

      try do
        found_files = Bundle.find_files(test_dir)

        # Should find all files
        assert length(found_files) >= 5

        # Check that specific files are found
        file_names = Enum.map(found_files, &Path.basename/1)
        assert "component1.js" in file_names
        assert "component2.js" in file_names
        assert "button.js" in file_names
        assert "helper.js" in file_names
        assert "README.md" in file_names
      after
        File.rm_rf!(test_dir)
      end
    end

    test "find_files handles empty directory" do
      tmp_dir = System.tmp_dir!()
      test_dir = Path.join(tmp_dir, "empty_test_#{System.unique_integer()}")
      File.mkdir_p!(test_dir)

      try do
        files = Bundle.find_files(test_dir)
        assert files == []
      after
        File.rm_rf!(test_dir)
      end
    end

    test "find_files handles permission errors gracefully" do
      # Test with a path that doesn't exist
      non_existent = "/tmp/definitely_does_not_exist_#{System.unique_integer()}"

      files = Bundle.find_files(non_existent)
      assert files == []
    end

    test "bundle task handles invalid arguments" do
      assert_raise ArgumentError, ~r/component_base dir does not exist/, fn ->
        Bundle.run(["--component-base", "/non/existent/path", "--output", "/tmp/output.js"])
      end
    end
  end
end
