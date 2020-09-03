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
      @object "object"
      @max_properties "maxProperties"
      @min_properties "minProperties"
      @required "required"

      @array "array"
      @max_items "maxItems"
      @min_items "minItems"

      @string "string"
      @min_length "minLength"
      @max_length "maxLength"
      @pattern "pattern"

      @number "number"
      @multiple_of "multipleOf"
      @maximum "maximum"
      @minimum "minimum"

      @type_ "type"
      @const "const"
      @boolean "boolean"
      @null "null"

      # Applicator
      @properties "properties"
      @patternProperties "patternProperties"
      @items "items"
      @all_of "allOf"
      @any_of "anyOf"
      @one_of "oneOf"

      # Meta-data
      @examples "examples"
      @title "title"
      @description "description"

      # Custom
      @props_order "order"
      @defs_order "defs_order"

      # Combination
      @types [@object, @array, @string, @boolean, @number, @null]

      # Older versions
      @definitions "definitions"
    end
  end
end
