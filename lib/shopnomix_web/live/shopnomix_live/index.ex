defmodule ShopnomixWeb.ShopnomixLive.Index do
  use ShopnomixWeb, :live_component

  def render(assigns) do
    ~H"""
    <div class="flex flex-col">
      <div>
        <p class="text-xl mx-2 mt-2">Welcome to our Word Processor Service</p>
      </div>
      <div class="ml-6 mt-2 text-blue-600"><.link href={~p"/insert"}>Insert</.link></div>
      <div class="ml-6 text-blue-600"><.link href={~p"/delete"}>Delete</.link></div>
      <div class="ml-6 text-blue-600"><.link href={~p"/replace"}>Replace</.link></div>
      <div class="ml-6 text-blue-600"><.link href={~p"/search"}>Search</.link></div>
    </div>
    """
  end
end
