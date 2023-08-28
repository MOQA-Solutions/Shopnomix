defmodule ShopnomixWeb.ShopnomixLive.Search do
  use ShopnomixWeb, :live_component

  def render(assigns) do
    ~H"""
    <div class="flex flex-col">
      <div class="mt-2 ml-2">
        <.link href={~p"/"}><span class="text-blue-600">&#8810 Back</span></.link>
      </div>
      <div>
        <.form for={@form} phx-submit="search">
          <div class="mt-2 ml-2 w-2/3">
            <.input type="text" field={@form[:substring]} label="Enter a SubString" />
          </div>
          <div class="mt-6 ml-6">
            <.button type="submit" class="bg-indigo-600">SEARCH</.button>
          </div>
        </.form>
      </div>
      <div class="mt-6 ml-2">
        <p class="font-mono">
          <%= if @search == true do %>
            <% {substring1, substring, substring2} = @search_data %>
            <%= substring1 %><span class="bg-yellow-400"><%= substring %></span><%= substring2 %>
          <% end %>
          <%= if @search == false do %>
            <%= @data %>
          <% end %>
        </p>
      </div>
    </div>
    """
  end
end
