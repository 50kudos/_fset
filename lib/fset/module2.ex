defmodule Fset.Module2 do
  alias Fset.Module2.Encode

  def encode(map, opts \\ []) do
    Encode.from_json_schema(map, opts)
  end
end
