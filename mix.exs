defmodule ROS.MixProject do
  use Mix.Project

  def project do
    [
      app: :ros,
      version: "0.1.0",
      elixir: "~> 1.5",
      elixirc_paths: elixirc_paths(Mix.env()),
      compilers: Mix.compilers(),
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      preferred_cli_env: [
        coveralls: :test,
        "coveralls.html": :test,
        credo: :test,
        bless: :test
      ],
      test_coverage: [tool: ExCoveralls],
      aliases: aliases(),
      msgs: messages()
    ]
  end

  def application do
    [
      # TODO: remove
      mod: {ROS.Application, []},
      extra_applications: [:logger, :runtime_tools]
    ]
  end

  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  defp deps do
    [
      {:cowboy, "~> 2.4"},
      {:xenium, git: "https://github.com/the-mikedavis/xenium.git"},
      {:bite, git: "https://github.com/the-mikedavis/bite.git"},
      {:satchel, git: "https://github.com/the-mikedavis/satchel.git"},

      # Testing and code hygiene, etc.
      {:private, "~> 0.1.1"},
      {:excoveralls, "~> 0.7", only: :test},
      {:credo, "~> 0.9", only: :test, runtime: false},
      {:dialyxir, "~> 0.5", only: [:dev, :test], runtime: false}
    ]
  end

  defp aliases do
    [
      bless: [&bless/1]
    ]
  end

  defp bless(_) do
    [
      {"format", ["--check-formatted"]},
      {"compile", ["--warnings-as-errors", "--force"]},
      {"coveralls.html", []},
      {"credo", []},
      {"dialyzer", []}
    ]
    |> Enum.each(fn {task, args} ->
      IO.ANSI.format([:cyan, "Running #{task} with args #{inspect(args)}"])
      |> IO.puts()

      Mix.Task.run(task, args)
    end)
  end

  defp messages do
    [
      {:grep, "std_msgs"},
      "sensor_msgs/Image"
    ]
  end
end
