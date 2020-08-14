defmodule Fset.Sch.New do
  use Fset.Sch.Vocab

  def object(), do: %{@type_ => @object, @props_order => [], @properties => %{}}
  def array(), do: %{@type_ => @array, @items => %{}}
  def array(:homo), do: array()
  def array(:hetero), do: %{@type_ => @array, @items => [string()]}
  def string(), do: %{@type_ => @string}
  def number(), do: %{@type_ => @number}
  def boolean(), do: %{@type_ => @boolean}
  def null(), do: %{@type_ => @null}
  def any(), do: %{}

  def all_of(schs) when is_list(schs) and length(schs) > 0, do: %{@all_of => schs}
  def any_of(schs) when is_list(schs) and length(schs) > 0, do: %{@any_of => schs}
  def one_of(schs) when is_list(schs) and length(schs) > 0, do: %{@one_of => schs}

  def ref(pointer) when is_binary(pointer), do: %{@ref => "#" <> pointer}
  def anchor(a) when is_binary(a), do: %{@anchor => a}
end
