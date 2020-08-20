defmodule Fset.Sch.New do
  use Fset.Sch.Vocab

  def object(opts \\ []),
    do: put_opts(%{@type_ => @object, @props_order => [], @properties => %{}}, opts)

  def array(type \\ :homo, opts \\ [])

  def array(:homo, opts),
    do: put_opts(%{@type_ => @array, @items => %{}}, opts)

  def array(:hetero, opts),
    do: put_opts(%{@type_ => @array, @items => [string()]}, opts)

  def array(type, opts),
    do: array(type, opts)

  def string(opts \\ []), do: put_opts(%{@type_ => @string}, opts)
  def number(opts \\ []), do: put_opts(%{@type_ => @number}, opts)
  def boolean(opts \\ []), do: put_opts(%{@type_ => @boolean}, opts)
  def null(opts \\ []), do: put_opts(%{@type_ => @null}, opts)
  def any(opts \\ []), do: put_opts(%{}, opts)
  def const(opts \\ []), do: put_opts(%{@const => nil}, opts)

  def all_of(schs, opts \\ []) when is_list(schs) and length(schs) > 0,
    do: put_opts(%{@all_of => schs}, opts)

  def any_of(schs, opts \\ []) when is_list(schs) and length(schs) > 0,
    do: put_opts(%{@any_of => schs}, opts)

  def one_of(schs, opts \\ []) when is_list(schs) and length(schs) > 0,
    do: put_opts(%{@one_of => schs}, opts)

  def ref(pointer) when is_binary(pointer),
    do: %{@ref => "#" <> pointer}

  def anchor(a) when is_binary(a),
    do: %{@anchor => a}

  defp put_opts(sch, opts) when is_map(sch) and is_list(opts) do
    Enum.reduce(opts, sch, fn
      {:anchor, true}, acc -> put_anchor(acc)
      {:anchor, a}, acc when is_binary(a) -> put_anchor(acc)
      {_opt, _val}, acc -> acc
    end)
  end

  defp put_anchor(sch, a \\ nil) do
    anchor = a || Ecto.UUID.generate()
    Map.put_new(sch, "$anchor", "a_" <> anchor)
  end
end
