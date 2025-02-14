defmodule Mix.Tasks.Phx.React.Bun.Bundle do
  @moduledoc """
  Create server.js bundle for `bun` runtime,
  bundle all components and render server in one file for otp release.

  ## Usage

  ```shell
  mix phx.react.bun.bundle --component-base=assets/component --output=priv/react/server.js
  ```

  """
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
        throw("component_base dir is not exists: #{base_dir}")
      end

    output = Keyword.get(opts, :output)
    IO.puts("Bundle component in directory [#{component_base}] into #{output}")

    files =
      components
      |> Enum.map(fn abs_path ->
        filename = Path.relative_to(abs_path, base_dir)
        ext = Path.extname(filename)
        basename = Path.basename(filename, ext)
        {basename, abs_path}
      end)

    quoted = EEx.compile_file("#{__DIR__}/server.js.eex")
    {result, _bindings} = Code.eval_quoted(quoted, files: files, base_dir: base_dir)
    tmp_file = "#{File.cwd!()}/server.js"
    File.write!(tmp_file, result)

    cd = Keyword.get(opts, :cd, File.cwd!())

    outdir = Path.dirname(output)

    if File.exists?(output) do
      File.rm!(output)
    end

    {out, code} =
      System.cmd("bun", ["build", "--target=bun", "--outdir=#{outdir}", tmp_file], cd: cd)

    IO.puts(~s[cd #{cd}; bun build --target=bun --outdir=#{outdir} #{tmp_file}])
    IO.puts("out #{code}: #{out}")

    if code != 0 do
      throw("bun build failed(#{code})")
    end

    if Path.join(outdir, "server.js") != output do
      File.rename(Path.join(outdir, "server.js"), output)
    end

    File.rm!(tmp_file)
  rescue
    error ->
      IO.inspect(error)
  catch
    error ->
      IO.inspect(error)
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
