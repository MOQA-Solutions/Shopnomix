defmodule Shopnomix.Operations.Insertion do
  use Ecto.Schema

  import Ecto.Changeset

  schema "insertions" do
    field(:substring, :string)
    field(:position, :integer)

    timestamps()
  end

  def changeset(insertion, params) do
    insertion
    |> cast(params, [:substring, :position])
    |> validate_required([:position])
    |> validate_number(:position, greater_than_or_equal_to: 0, less_than: 1_000_000)
  end
end
