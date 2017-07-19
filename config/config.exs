# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
use Mix.Config


if Mix.env == :dev do
  config :mix_test_watch,
    tasks: [
      "test",
      # "dialyzer"
      # "credo list --format oneline --strict"
    ]
end
