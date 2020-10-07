defmodule Fset.Main do
  @moduledoc """
  Main Fset application works on highest level closed to web framework such as
  Liveview event handler. And only manage inputs from boundary, feed into a blackbox
  layer, then manage output to be returned.
  """
  @file_topic "module_update:"

  alias Fset.Module
  alias FsetWeb.Presence

  def subscribe_file_update(file) do
    Phoenix.PubSub.subscribe(Fset.PubSub, @file_topic <> file.id)
  end

  def track_user(user, file) do
    Presence.track(self(), @file_topic <> file.id, user.id, %{
      current_path: file.id,
      current_edit: nil,
      pid: self()
    })
  end

  @doc """
  Add a sch to a container sch such as object, array or union.
  """
  def add_field(schema, path, model_type) do
    {_pre, _post, _new_schema} = Module.add_field(schema, path, model_type)
  end

  def add_model(schema, path, model_type) do
    {_pre, _post, _new_schema} = Module.add_model(schema, path, model_type)
  end

  def broadcast_update_sch(topic, path, sch) when is_binary(topic) do
    Phoenix.PubSub.broadcast!(
      Fset.PubSub,
      topic,
      {:update_sch, path, sch}
    )
  end

  def broadcast_update_sch(%_{id: id}, path, sch) do
    Phoenix.PubSub.broadcast!(
      Fset.PubSub,
      @file_topic <> id,
      {:update_sch, path, sch}
    )
  end
end
