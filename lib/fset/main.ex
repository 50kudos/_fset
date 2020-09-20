defmodule Fset.Main do
  @moduledoc """
  Main Fset application works on highest level closed to web framework such as
  Liveview event handler.
  """
  @file_topic "module_update:"

  alias Fset.Module

  @doc """
  Add a sch to a container sch such as object, array or union.
  """
  def add_field(schema, path, model_type) do
    {_pre, _post, _new_schema} = Module.add_field(schema, path, model_type)
  end

  def broadcast_update_sch(file, path, sch) do
    Phoenix.PubSub.broadcast!(
      Fset.PubSub,
      @file_topic <> file.id,
      {:update_sch, path, sch}
    )
  end
end