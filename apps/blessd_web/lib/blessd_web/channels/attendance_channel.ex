defmodule BlessdWeb.AttendanceChannel do
  use BlessdWeb, :channel

  alias Blessd.Memberships
  alias Blessd.Observance
  alias BlessdWeb.AttendanceView
  alias Phoenix.View

  def join("attendance:lobby", _payload, socket) do
    {:ok, socket}
  end

  def handle_in("search", %{"meeting_occurrence_id" => occurrence_id, "query" => query}, socket) do
    with user = socket.assigns.current_user,
         {:ok, occurrence} <- Observance.find_occurrence(occurrence_id, user),
         {:ok, people} <- Observance.search_people(query, user) do
      html =
        View.render_to_string(AttendanceView, "table_body.html",
          people: people,
          occurrence: occurrence
        )

      {:reply, {:ok, %{table_body: html}}, socket}
    else
      {:error, :not_found} ->
        {:reply, {:error, %{message: "Occurrence not found"}}, socket}

      {:error, :unauthorized} ->
        {:reply, {:error, %{message: "Unauthorized user"}}, socket}

      {:error, :unconfirmed} ->
        {:reply, {:error, %{message: "Unconfirmed user"}}, socket}
    end
  end

  def handle_in(
        "create",
        %{"person" => person_params, "meeting_occurrence_id" => occurrence_id},
        socket
      ) do
    with user = socket.assigns.current_user,
         {:ok, person} <- Memberships.create_person(person_params, user),
         {:ok, occurrence} <- Observance.find_occurrence(occurrence_id, user),
         {:ok, people} <- Observance.search_people(person.name, user) do
      html =
        View.render_to_string(AttendanceView, "table_body.html",
          people: people,
          occurrence: occurrence
        )

      {:reply, {:ok, %{table_body: html}}, socket}
    else
      {:error, %Ecto.Changeset{} = changeset} ->
        {:reply, {:error, errors_from_changeset(changeset)}, socket}

      {:error, :not_found} ->
        {:reply, {:error, %{message: "Occurrence not found"}}, socket}

      {:error, :unauthorized} ->
        {:reply, {:error, %{message: "Unauthorized user"}}, socket}

      {:error, :unconfirmed} ->
        {:reply, {:error, %{message: "Unconfirmed user"}}, socket}
    end
  end

  def handle_in(
        "update_state",
        %{"person_id" => person_id, "meeting_occurrence_id" => occurrence_id, "state" => state},
        socket
      ) do
    with user = socket.assigns.current_user,
         {:ok, occurrence} <- Observance.find_occurrence(occurrence_id, user),
         {:ok, person} <-
           Observance.update_attendant_state(
             person_id,
             occurrence_id,
             state,
             user
           ) do
      html =
        View.render_to_string(AttendanceView, "table_row.html",
          person: person,
          occurrence: occurrence
        )

      {:reply, {:ok, %{table_row: html}}, socket}
    else
      {:error, %Ecto.Changeset{} = changeset} ->
        {:reply, {:error, errors_from_changeset(changeset)}, socket}

      {:error, :unauthorized} ->
        {:reply, {:error, %{message: "Unauthorized user"}}, socket}

      {:error, :unconfirmed} ->
        {:reply, {:error, %{message: "Unconfirmed user"}}, socket}
    end
  end

  defp errors_from_changeset(%Ecto.Changeset{errors: errors}) do
    errors
    |> Stream.map(fn {field, {msg, _}} -> {field, msg} end)
    |> Enum.into(%{})
  end
end
