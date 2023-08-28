defmodule ShopnomixWeb.ShopnomixLive.Insert do
  use ShopnomixWeb, :live_component

  def render(assigns) do
    ~H"""
    <div class="flex flex-col">
      <div class="mt-2 ml-2">
        <.link href={~p"/"}><span class="text-blue-600">&#8810 Back</span></.link>
      </div>
      <div>
        <.form for={@form} phx-submit="insert">
          <div class="mt-2 ml-2 w-2/3">
            <.input type="text" field={@form[:substring]} label="Enter a SubString" />
          </div>
          <div class="mt-6 ml-2 w-2/3">
            <.input type="number" field={@form[:position]} label="Enter the Position starting from 0" />
          </div>
          <div class="mt-6 ml-6">
            <.button type="submit" class="bg-indigo-600">INSERT</.button>
          </div>
        </.form>
      </div>
      <div class="mt-6 ml-2 ">
        <p class="font-mono"><%= @data %></p>
      </div>
    </div>
    """
  end
end
