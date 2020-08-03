defmodule Fset.Emap do
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
end
