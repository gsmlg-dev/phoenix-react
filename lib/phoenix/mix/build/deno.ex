defmodule Mix.Tasks.Phx.React.Deno.Bundle do
  @moduledoc """
  Create server.js bundle for `deno` runtime,
  bundle all components and render server in one file for otp release.

  ## Usage

  ```shell
  mix phx.react.deno.bundle --component-base=assets/component --output=priv/react/server.js
  ```

  """
  require Logger

  use Mix.Task

  @shortdoc "Bundle components into server.js"
  def run(args) do
    {opts, _argv} =
      OptionParser.parse!(args, strict: [component_base: :string, output: :string, cd: :string])

    component_base = Keyword.get(opts, :component_base)
    base_dir = Path.absname(component_base, File.cwd!()) |> Path.expand()

    components =
      if File.dir?(base_dir) do
        find_files(base_dir)
      else
        raise ArgumentError, "component_base dir does not exist: #{base_dir}"
      end

    output = Keyword.get(opts, :output)
    Logger.info("Bundle component in directory [#{component_base}] into #{output}")

    cd = Keyword.get(opts, :cd, File.cwd!())

    # Create JSX files for Deno
    jsx_dir = Path.join(Path.dirname(output), "jsx_components")
    File.mkdir_p!(jsx_dir)
    # Clean up first
    File.rm_rf!(jsx_dir)
    File.mkdir_p!(jsx_dir)

    files =
      components
      |> Enum.map(fn abs_path ->
        filename = Path.relative_to(abs_path, base_dir)
        ext = Path.extname(filename)
        basename = Path.basename(filename, ext)

        # Create JSX version for Deno
        jsx_path = Path.join(jsx_dir, "#{basename}.jsx")
        File.cp!(abs_path, jsx_path)

        {basename, jsx_path}
      end)

    quoted = EEx.compile_file("#{__DIR__}/server_deno.js.eex")

    {result, _bindings} =
      Code.eval_quoted(quoted, files: files, base_dir: base_dir, output: output)

    _outdir = Path.dirname(output)

    if File.exists?(output) do
      File.rm!(output)
    end

    # Check if this is a source file (ends with _source.js) or binary output
    if String.ends_with?(output, "_source.js") do
      # For development, fix import paths to be relative and write the source file
      jsx_dir = Path.join(Path.dirname(output), "jsx_components")
      result = String.replace(result, "\"#{jsx_dir}/", "\"./jsx_components/")
      File.write!(output, result)
      Logger.info("Created Deno source file: #{output}")
    else
      # For production, create binary
      tmp_file = "#{cd}/server_deno.js"
      File.write!(tmp_file, result)

      # Deno 2.x removed bundle, use compile instead
      {out, code} =
        System.cmd("deno", ["compile", "--output", output, tmp_file], cd: cd)

      Logger.info(~s[cd #{cd}; deno compile --output #{output} #{tmp_file}])
      Logger.info("out #{code}: #{out}")

      if code != 0 do
        throw("deno compile failed(#{code})")
      end

      File.rm!(tmp_file)
    end

    # Clean up JSX files only for production builds
    unless String.ends_with?(output, "_source.js") do
      File.rm_rf!(jsx_dir)
    end
  rescue
    error ->
      Logger.error("Build failed: #{Exception.format(:error, error, __STACKTRACE__)}")
      reraise error, __STACKTRACE__
  catch
    :throw, error ->
      Logger.error("Build failed: #{inspect(error)}")
      throw(error)

    :exit, error ->
      Logger.error("Build failed: #{inspect(error)}")
      exit(error)
  end

  def find_files(dir) do
    find_files(dir, [])
  end

  defp find_files(dir, acc) do
    case File.ls(dir) do
      {:ok, entries} ->
        entries
        |> Enum.reduce(acc, fn entry, acc ->
          path = Path.join(dir, entry)

          cond do
            # Recurse into subdirectories
            File.dir?(path) -> find_files(path, acc)
            # Collect files
            File.regular?(path) -> [path | acc]
            true -> acc
          end
        end)

      # Ignore errors (e.g., permission issues)
      {:error, _} ->
        acc
    end
  end
end
