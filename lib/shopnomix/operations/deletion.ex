defmodule Shopnomix.Operations.Deletion do
  use Ecto.Schema

  import Ecto.Changeset

  schema "deletions" do
    field(:substring, :string)

    timestamps()
  end

  def changeset(deletion, params) do
    deletion
    |> cast(params, [:substring])
  end
end
