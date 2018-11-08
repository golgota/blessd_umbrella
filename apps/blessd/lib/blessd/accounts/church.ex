defmodule Blessd.Accounts.Church do
  use Ecto.Schema

  alias Blessd.Accounts.Church
  alias Blessd.Changeset.Church, as: ChurchChangeset

  schema "churches" do
    field(:name, :string)
    field(:identifier, :string)

    timestamps()
  end

  @doc false
  def changeset(%Church{} = church, attrs) do
    ChurchChangeset.changeset(church, attrs)
  end
end
