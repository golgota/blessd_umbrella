defmodule BlessdWeb.PersonController do
  use BlessdWeb, :controller

  alias Blessd.Observance
  alias Blessd.Memberships
  alias Blessd.Shared

  def index(conn, _params) do
    with user = conn.assigns.current_user,
         {:ok, people} <- Memberships.list_people(user),
         {:ok, fields} <- Shared.list_custom_fields("person", user) do
      render(conn, "index.html", people: people, fields: fields)
    end
  end

  def new(conn, _params) do
    with user = conn.assigns.current_user,
         {:ok, person} <- Memberships.new_person(user),
         {:ok, changeset} <- Memberships.change_person(person, user),
         {:ok, fields} <- Shared.list_custom_fields("person", user) do
      render(conn, "new.html", changeset: changeset, fields: fields)
    end
  end

  def create(conn, %{"meeting_occurrence_id" => occurrence_id, "person" => person_params}) do
    with user = conn.assigns.current_user,
         {:ok, person} <- Memberships.create_person(person_params, user),
         {:ok, occurrence} <- Observance.find_occurrence(occurrence_id, user) do
      conn
      |> put_flash(:info, gettext("Visitor successfully created."))
      |> redirect(
        to:
          Routes.meeting_occurrence_path(
            conn,
            :show,
            user.church.slug,
            occurrence,
            search: person.name
          )
      )
    end
  end

  def create(conn, %{"person" => person_params}) do
    user = conn.assigns.current_user

    with {:ok, _person} <- Memberships.create_person(person_params, user) do
      conn
      |> put_flash(:info, gettext("Person created successfully."))
      |> redirect(to: Routes.person_path(conn, :index, user.church.slug))
    else
      {:error, %Ecto.Changeset{} = changeset} ->
        with {:ok, fields} <- Shared.list_custom_fields("person", user) do
          render(conn, "new.html", changeset: changeset, fields: fields)
        end

      {:error, reason} ->
        {:error, reason}
    end
  end

  def edit(conn, %{"id" => id}) do
    with user = conn.assigns.current_user,
         {:ok, person} <- Memberships.find_person(id, user),
         {:ok, changeset} <- Memberships.change_person(person, user),
         {:ok, fields} <- Shared.list_custom_fields("person", user) do
      render(conn, "edit.html", changeset: changeset, fields: fields)
    end
  end

  def update(conn, %{"id" => id, "person" => person_params}) do
    user = conn.assigns.current_user

    with {:ok, person} <- Memberships.find_person(id, user),
         {:ok, _person} <- Memberships.update_person(person, person_params, user) do
      conn
      |> put_flash(:info, gettext("Person updated successfully."))
      |> redirect(to: Routes.person_path(conn, :index, user.church.slug))
    else
      {:error, %Ecto.Changeset{} = changeset} ->
        with {:ok, fields} <- Shared.list_custom_fields("person", user) do
          render(conn, "edit.html", changeset: changeset, fields: fields)
        end

      {:error, reason} ->
        {:error, reason}
    end
  end

  def delete(conn, %{"id" => id}) do
    with user = conn.assigns.current_user,
         {:ok, person} <- Memberships.find_person(id, user),
         {:ok, _person} = Memberships.delete_person(person, user) do
      conn
      |> put_flash(:info, gettext("Person deleted successfully."))
      |> redirect(to: Routes.person_path(conn, :index, user.church.slug))
    end
  end
end
