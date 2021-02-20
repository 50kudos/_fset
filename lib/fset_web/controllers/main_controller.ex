defmodule FsetWeb.MainController do
  use FsetWeb, :controller
  import Fset.Main

  def index(conn, params) do
    assigns1 = init_data(params)
    assigns2 = change_file_data(assigns1, params)

    assigns = Map.merge(assigns1, assigns2)

    assigns =
      Map.update!(assigns, :ui, fn ui ->
        ui
        |> Map.put_new(:tab, 1.5)
        |> Map.put_new(:level, 1)
        |> Map.put_new(:model_number, false)
        |> Map.put_new(:file_id, assigns.current_file.id)
        |> Map.put(:model_names, models_anchors(assigns.files))
        |> Map.put(:parent_path, assigns.current_file.id)
        |> case do
          %{model_number: true} = ui -> %{ui | tab: 3}
          ui -> ui
        end
      end)

    render(conn, "show.html", assigns)
  end

  def show(conn, params) do
    assigns1 = init_data(params)
    assigns2 = change_file_data(assigns1, params)

    assigns = Map.merge(assigns1, assigns2)

    assigns =
      Map.update!(assigns, :ui, fn ui ->
        ui
        |> Map.put_new(:tab, 1.5)
        |> Map.put_new(:level, 1)
        |> Map.put_new(:model_number, false)
        |> Map.put_new(:file_id, assigns.current_file.id)
        |> Map.put(:model_names, models_anchors(assigns.files))
        |> Map.put(:parent_path, assigns.current_file.id)
        |> case do
          %{model_number: true} = ui -> %{ui | tab: 3}
          ui -> ui
        end
      end)

    render(conn, "show.html", assigns)
  end
end
