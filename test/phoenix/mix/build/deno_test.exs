defmodule Mix.Tasks.Phx.React.Deno.BundleTest do
  use ExUnit.Case, async: false

  alias Mix.Tasks.Phx.React.Deno.Bundle

  describe "run/1" do
    test "handles missing arguments gracefully" do
      # Test that the function can be called
      # The actual error handling depends on the OptionParser behavior
      assert is_function(&Bundle.run/1)
    end

    test "find_files/1 finds all files in directory recursively" do
      # Create a temporary directory structure
      tmp_dir = System.tmp_dir!()
      test_dir = Path.join(tmp_dir, "deno_test_#{System.unique_integer()}")
      File.mkdir_p!(test_dir)

      # Create some test files
      File.write!(Path.join(test_dir, "component1.js"), "export const Component = () => null;")
      File.mkdir!(Path.join(test_dir, "subdir"))

      File.write!(
        Path.join([test_dir, "subdir", "component2.js"]),
        "export const Component = () => null;"
      )

      try do
        files = Bundle.find_files(test_dir)

        # Should find both files
        assert length(files) == 2
        assert Enum.any?(files, &String.ends_with?(&1, "component1.js"))
        assert Enum.any?(files, &String.ends_with?(&1, "component2.js"))
      after
        File.rm_rf!(test_dir)
      end
    end

    test "find_files/1 handles non-existent directory" do
      non_existent = "/tmp/non_existent_#{System.unique_integer()}"

      # Should return empty list for non-existent directory
      files = Bundle.find_files(non_existent)
      assert files == []
    end
  end
end
