defmodule Blessd.Observance.Attendant do
  use Ecto.Schema

  import Ecto.Changeset
  import Ecto.Query

  alias Blessd.Auth.Church
  alias Blessd.Observance.Person
  alias Blessd.Observance.Service

  schema "attendants" do
    belongs_to(:church, Church)

    belongs_to(:service, Service)
    belongs_to(:person, Person)

    timestamps()
  end

  @doc false
  def changeset(attendant, attrs) do
    attendant
    |> cast(attrs, [:service_id, :person_id])
    |> basic_validations()
  end

  defp basic_validations(changeset) do
    validate_required(changeset, [:service_id, :person_id])
  end

  def order(query) do
    if has_named_binding?(query, :person) do
      order_by(query, [a, person: p], p.name)
    else
      order_by(query, [a], a.inserted_at)
    end
  end

  def preload(query) do
    query
    |> join(:inner, [a], p in assoc(a, :person), as: :person)
    |> preload([a, person: p], person: p)
  end

  def by_service(query, %Service{id: service_id}), do: by_service(query, service_id)
  def by_service(query, service_id), do: where(query, [a], a.service_id == ^service_id)
end
