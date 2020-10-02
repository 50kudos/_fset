defmodule Fset.Utils do
  @moduledoc """
  Uncategoried utility functions across project
  """

  def gen_key(prefix \\ "key") do
    id = DateTime.to_unix(DateTime.now!("Etc/UTC"), :microsecond)
    id = String.slice("#{id}", 6..-1)
    "#{prefix}_#{to_string(id)}"
  end

  def put_dup(map, key, val) when is_binary(key) do
    if Map.has_key?(map, key) do
      Map.put(map, key <> "[dup]", val)
    else
      Map.put(map, key, val)
    end
  end

  def word_break_html(string) when is_binary(string) do
    ~r/(?<=::)|(?<=\.)|(?<=_)/
    |> Regex.split(string)
    |> Enum.flat_map(fn a ->
      Macro.underscore(a)
      |> String.split("_")
      |> Enum.map(&String.capitalize/1)
    end)
    |> Enum.intersperse({:safe, "<wbr>"})
  end

  def unwrap(term_or_list, default \\ nil) do
    case term_or_list do
      [] -> default
      [term] -> term
      terms -> terms
    end
  end

  def aws_specs_sch() do
    Path.expand("../../test/support/fixtures/sch_samples/all-spec.json", __DIR__)
    |> File.read!()
    |> Jason.decode!()
  end

  def github_action_sch() do
    Path.expand("../../test/support/fixtures/sch_samples/github-action.json", __DIR__)
    |> File.read!()
    |> Jason.decode!()
  end
end
