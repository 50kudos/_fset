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

  # Break words by delimiter ".", "::", "_" or camelCase/PascalCase.
  # But do not break too early, we keep at least 30% of split chucks. And also
  # don't break if there's only 1 <wbr>. If text is still overflow, try new delimiter
  # to split.
  def word_break_html(string) when is_binary(string) do
    chucks = Regex.split(~r/(?<=::)|(?<=\.)|(?<=_)|(?=[A-Z][a-z]*)/, string)

    chucks_count = Enum.count(chucks)
    keep_count = ceil(0.3 * chucks_count)
    keep = Enum.slice(chucks, 0..keep_count)
    break = Enum.slice(chucks, (keep_count + 1)..-1)

    if Enum.count(break) < 3 do
      keep ++ break
    else
      keep ++ Enum.intersperse(break, {:safe, "<wbr>"})
    end
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
