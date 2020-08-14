defmodule Fset.Sch.Vocab do
  # "https://json-schema.org/draft/2019-09/vocab/core"
  # "https://json-schema.org/draft/2019-09/vocab/applicator"
  # "https://json-schema.org/draft/2019-09/vocab/validation"

  # Changing keyword value MUST only be done by a dedicate schema transformation process.
  # it needs to "stop the world" and transform safely. One of possible use case is schema compression.
  # Idealy we would not change that on the fly without good reason. We do that in schema export process.
  defmacro __using__([]) do
    quote do
      # Core
      @id "$id"
      @ref "$ref"
      @defs "$defs"
      @anchor "$anchor"

      # Validation
      @type_ "type"
      @object "object"
      @array "array"
      @string "string"
      @boolean "boolean"
      @number "number"
      @null "null"
      @const "const"

      # Applicator
      @properties "properties"
      @items "items"
      @all_of "allOf"
      @any_of "anyOf"
      @one_of "oneOf"

      # Custom
      @props_order "order"

      # Combination
      @types [@object, @array, @string, @boolean, @number, @null]
    end
  end
end
