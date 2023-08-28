defmodule ShopnomixWeb.ShopnomixLive.ShopnomixLive do
  use ShopnomixWeb, :live_view

  import Phoenix.Component

  alias Phoenix.PubSub
  alias Shopnomix.Operations
  alias Shopnomix.Operations.Insertion
  alias Shopnomix.Operations.Deletion
  alias Shopnomix.Operations.Replacement
  alias Shopnomix.Operations.Search

  @pubsub Shopnomix.PubSub

  def mount(_params, _session, socket) do
    PubSub.subscribe(@pubsub, "text")
    {:ok, socket, layout: false}
  end

  ######

  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  ######

  def handle_event("insert", %{"insertion" => params}, socket) do
    case Operations.insert(params) do
      {:ok, new_data} ->
        form =
          %Insertion{}
          |> Operations.change_insertion()
          |> to_form

        PubSub.broadcast(@pubsub, "text", {:data, new_data})
        {:noreply, assign(socket, data: new_data, form: form)}

      {:error, changeset} ->
        form =
          changeset
          |> Map.put(:action, :insert)
          |> to_form

        {:noreply, assign(socket, form: form)}
    end
  end

  def handle_event("delete", %{"deletion" => params}, socket) do
    form =
      %Deletion{}
      |> Operations.change_deletion()
      |> to_form

    case Operations.delete(params) do
      {:ok, new_data} ->
        PubSub.broadcast(@pubsub, "text", {:data, new_data})
        {:noreply, assign(socket, data: new_data, form: form)}

      :ok ->
        {:noreply, assign(socket, form: form)}
    end
  end

  def handle_event("replace", %{"replacement" => params}, socket) do
    form =
      %Replacement{}
      |> Operations.change_replacement()
      |> to_form

    case Operations.replace(params) do
      {:ok, new_data} ->
        PubSub.broadcast(@pubsub, "text", {:data, new_data})
        {:noreply, assign(socket, data: new_data, form: form)}

      :ok ->
        {:noreply, assign(socket, form: form)}
    end
  end

  def handle_event("search", %{"search" => params}, socket) do
    form =
      %Search{}
      |> Operations.change_search()
      |> to_form

    case Operations.search(params) do
      {:ok, new_data} ->
        {:noreply, assign(socket, form: form, search: true, search_data: new_data)}

      :ok ->
        {:noreply, assign(socket, form: form)}
    end
  end

  #####

  def handle_info({:data, data}, socket) do
    {:noreply, assign(socket, data: data, search: false)}
  end

  #####

  # private functions

  defp apply_action(socket, :index, _params) do
    socket
  end

  defp apply_action(socket, :insert, _params) do
    {:ok, data} = Processor.get()

    form =
      %Insertion{}
      |> Operations.change_insertion()
      |> to_form

    assign(socket, data: data, form: form)
  end

  defp apply_action(socket, :delete, _params) do
    {:ok, data} = Processor.get()

    form =
      %Deletion{}
      |> Operations.change_deletion()
      |> to_form

    assign(socket, data: data, form: form)
  end

  defp apply_action(socket, :replace, _params) do
    {:ok, data} = Processor.get()

    form =
      %Replacement{}
      |> Operations.change_replacement()
      |> to_form

    assign(socket, data: data, form: form)
  end

  defp apply_action(socket, :search, _params) do
    {:ok, data} = Processor.get()

    form =
      %Search{}
      |> Operations.change_search()
      |> to_form

    assign(socket, data: data, form: form, search: false, search_data: nil)
  end
end
