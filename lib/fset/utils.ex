defmodule Fset.Utils do
  @moduledoc """
  Provide extra functions to Map module
  """

  def put_dup(map, key, val) when is_binary(key) do
    if Map.has_key?(map, key) do
      Map.put(map, key <> "[dup]", val)
    else
      Map.put(map, key, val)
    end
  end

  def word_break_html(string) when is_binary(string) do
    ~r/(?<=::)|(?<=\.)/
    |> Regex.split(string)
    |> Enum.intersperse({:safe, "<wbr>"})
  end
end
