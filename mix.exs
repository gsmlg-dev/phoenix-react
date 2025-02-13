defmodule Phoenix.React.Mixfile do
  use Mix.Project

  @source_url "https://github.com/gsmlg-dev/phoenix-react.git"
  @version "0.3.0"

  def project do
    [
      app: :phoenix_react_server,
      version: @version,
      elixir: "~> 1.14.1 or ~> 1.15",
      config_path: "config/config.exs",
      deps: deps(),
      name: "Phoenix.React",
      description: """
      Phoenix.React is use for renders React component as Phoenix Component in heex template.
      Support render_to_string and render_to_static_markup and cache render result.
      Only render to string support hyrate react component with phx-hook.
      """,
      package: package(),
      aliases: aliases(),
      elixirc_paths: elixirc_paths(Mix.env()),
      docs: [
        extras: ["CHANGELOG.md", "README.md"],
        source_url: @source_url,
        source_ref: "v#{@version}",
        main: "readme",
        skip_undefined_reference_warnings_on: ["CHANGELOG.md"]
      ]
    ]
  end

  def application do
    [
      extra_applications: [:eex, :logger],
      env: [csrf_token_reader: {Plug.CSRFProtection, :get_csrf_token_for, []}]
    ]
  end

  # Specifies which paths to compile per environment.
  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  defp deps do
    [
      {:jason, "~> 1.2"},
      {:httpoison, "~> 2.0"},
      {:phoenix_html, "~> 4.1"},
      {:phoenix_live_view, "~> 1.0"},
      {:file_system, "~> 1.0"},
      {:ex_doc, ">= 0.0.0", only: :doc, runtime: false}
    ]
  end

  defp package do
    [
      maintainers: ["Jonathan Gao"],
      licenses: ["MIT"],
      files: ~w(lib priv CHANGELOG.md LICENSE mix.exs README.md),
      links: %{
        Changelog: "https://hexdocs.pm/phoenix_react_server/changelog.html",
        GitHub: @source_url
      }
    ]
  end

  defp aliases do
    []
  end
end
