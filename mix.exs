defmodule TemplateModuleName.Mixfile do
  use Mix.Project

  @source_url "https://github.com/gsmlg-dev/<app_otp_name>.git"
  @version "0.0.0"

  def project do
    [
      app: :<app_otp_name>,
      version: @version,
      elixir: "~> 1.7",
      config_path: "config/config.exs",
      deps: deps(),
      name: "TemplateModuleName",
      description: "Description of this package",
      package: package(),
      aliases: aliases(),
      docs: [
        extras: ["CHANGELOG.md"],
        source_url: @source_url,
        source_ref: "v#{@version}",
        main: "TemplateModuleName",
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

  defp deps do
    [
      {:ex_doc, ">= 0.0.0", only: :prod, runtime: false}
    ]
  end

  defp package do
    [
      maintainers: ["Jonathan Gao"],
      licenses: ["MIT"],
      files: ~w(lib priv CHANGELOG.md LICENSE mix.exs README.md),
      links: %{
        Changelog: "https://hexdocs.pm/<app_otp_name>/changelog.html",
        GitHub: @source_url
      }
    ]
  end

  defp aliases do
    []
  end
end
