defmodule Shopnomix.Operations do
  alias Shopnomix.Operations.Insertion
  alias Shopnomix.Operations.Deletion
  alias Shopnomix.Operations.Replacement
  alias Shopnomix.Operations.Search

  def change_insertion(%Insertion{} = insertion, attrs \\ %{}),
    do: Insertion.changeset(insertion, attrs)

  def change_deletion(%Deletion{} = deletion, attrs \\ %{}),
    do: Deletion.changeset(deletion, attrs)

  def change_replacement(%Replacement{} = replacement, attrs \\ %{}),
    do: Replacement.changeset(replacement, attrs)

  def change_search(%Search{} = search, attrs \\ %{}), do: Search.changeset(search, attrs)

  @spec insert(params :: map()) :: {:ok, String.t()} | {:error, Ecto.Schema.t()}
  def insert(params) do
    insertion = change_insertion(%Insertion{}, params)

    case insertion.errors do
      [] ->
        substring = params["substring"]
        pos = String.to_integer(params["position"])
        Processor.insert(substring, pos)

      _ ->
        {:error, insertion}
    end
  end

  @spec delete(params :: map()) :: :ok | {:ok, String.t()}
  def delete(params) do
    substring = params["substring"]

    case substring do
      "" ->
        :ok

      _ ->
        stringlist = String.split(substring, ",")
        Processor.delete(stringlist)
    end
  end

  @spec replace(params :: map()) :: :ok | {:ok, String.t()}
  def replace(params) do
    substring1 = params["substring1"]
    substring2 = params["substring2"]

    case substring1 do
      "" ->
        :ok

      _ ->
        Processor.replace(substring1, substring2)
    end
  end

  @spec search(params :: map()) :: :ok | {:ok, {String.t(), String.t(), String.t()}}
  def search(params) do
    substring = params["substring"]

    case substring do
      "" ->
        :ok

      _ ->
        Processor.search(substring)
    end
  end
end
