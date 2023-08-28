defmodule Shopnomix.Operations.Search do
  use Ecto.Schema

  import Ecto.Changeset

  schema "searchs" do
    field(:substring, :string)

    timestamps()
  end

  def changeset(search, params) do
    search
    |> cast(params, [:substring])
  end
end
