defmodule Fset.Module.Encode do
  alias Fset.Sch
  alias Fset.Module

  def from_json_schema(sch) do
    defs =
      Enum.reduce(Sch.defs(sch), %{}, fn {def, sch}, acc ->
        Map.put(acc, def, encode(sch))
      end)

    Module.put_model(Module.new_sch(), defs)
  end

  defp encode(sch, acc \\ %{})

  defp encode(sch, _acc) do
    sch
  end
end
