defmodule Mix.Tasks.Phx.React.Bun.Bundle do
  @moduledoc """
  Create server.js bundle for `bun` runtime,
  bundle all components and render server in one file for otp release.

  ## Usage

  ```shell
  mix phx.react.bun.bundle --component-base=assets/component --output-file=priv/react/server.js
  ```

  """
  use Mix.Task

  @shortdoc "Bundle components into server.js"
  def run(args) do
    Mix.Task.run("app.start")
    {opts, names, reset} =
      OptionParser.parse(args, switches: [verbose: :boolean, count: :integer])
    IO.inspect args
    IO.inspect {opts, names, reset}
  end
end
