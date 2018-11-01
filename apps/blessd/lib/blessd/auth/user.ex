defmodule Blessd.Auth.User do
  use Ecto.Schema

  alias Blessd.Auth.Church

  schema "users" do
    belongs_to(:church, Church)

    field(:name, :string)
    field(:email, :string)
  end
end