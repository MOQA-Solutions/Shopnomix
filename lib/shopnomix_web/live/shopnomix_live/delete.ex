defmodule ShopnomixWeb.ShopnomixLive.Delete do
  use ShopnomixWeb, :live_component

  def render(assigns) do
    ~H"""
    <div class="flex flex-col">
      <div class="mt-2 ml-2">
        <.link href={~p"/"}><span class="text-blue-600">&#8810 Back</span></.link>
      </div>
      <div>
        <.form for={@form} phx-submit="delete">
          <div class="mt-2 ml-2">
            <.input
              type="text"
              field={@form[:substring]}
              label="Enter a Range of SubStrings separated by COMMAS"
            />
          </div>
          <div class="mt-6 ml-6">
            <.button type="submit" class="bg-indigo-600">DELETE</.button>
          </div>
        </.form>
      </div>
      <div class="mt-6 ml-2">
        <p class="font-mono"><%= @data %></p>
      </div>
    </div>
    """
  end
end
