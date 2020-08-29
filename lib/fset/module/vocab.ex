defmodule Fset.Module.Vocab do
  defmacro __using__([]) do
    quote do
      @model_key "__MODEL__"
      @main_key "__MAIN__"
      @logic_key "__LOGIC__"
      @var_key "__VAR__"

      @model_anchor "MODEL"
      @main_anchor "MAIN"
      @logic_anchor "LOGIC"
    end
  end
end
