defmodule Sammal.Mixfile do
  use Mix.Project

  def project do
    [app: :sammal,
     version: "0.1.0",
     elixir: "~> 1.4",
     build_embedded: Mix.env == :prod,
     start_permanent: Mix.env == :prod,
     escript: [main_module: Sammal],
     deps: deps(),
     dialyzer: [
       flags: ["-Wunmatched_returns", :error_handling, :race_conditions, :underspecs]
     ],
     package: [
       description: "A compiler for a Scheme-ish language (coursework)",
       licenses: ["MIT"],
       links: %{source: "https://github.com/epiphone/sammal/"},
       maintainers: ["aleksipekkala@hotmail.com"]
     ],
     name: "Sammal",
     source_url: "https://github.com/epiphone/sammal/",
     homepage_url: "https://github.com/epiphone/sammal/"]
  end

  # Configuration for the OTP application
  #
  # Type "mix help compile.app" for more information
  def application do
    # Specify extra applications you'll use from Erlang/Elixir
    [extra_applications: [:logger]]
  end

  # Dependencies can be Hex packages:
  #
  #   {:my_dep, "~> 0.3.0"}
  #
  # Or git/path repositories:
  #
  #   {:my_dep, git: "https://github.com/elixir-lang/my_dep.git", tag: "0.1.0"}
  #
  # Type "mix help deps" for more examples and options
  defp deps do
    [{:credo, "~> 0.8", only: [:dev, :test], runtime: false},
     {:mix_test_watch, "~> 0.3", only: :dev, runtime: false},
     {:dialyxir, "~> 0.5", only: [:dev, :test], runtime: false},
     {:ex_doc, "~> 0.14", only: :dev, runtime: false}]
  end
end
