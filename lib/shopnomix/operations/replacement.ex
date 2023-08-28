defmodule Shopnomix.Operations.Replacement do
  use Ecto.Schema

  import Ecto.Changeset

  schema "replacements" do
    field(:substring1, :string)
    field(:substring2, :string)
    timestamps()
  end

  def changeset(replacement, params) do
    replacement
    |> cast(params, [:substring1, :substring2])
  end
end
