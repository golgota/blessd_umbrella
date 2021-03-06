defmodule Blessd.Observance.Meetings.Occurrences do
  @moduledoc """
  Secondary context for meeting occurrences
  """

  import Ecto.Query

  alias Blessd.Observance.Meetings.Meeting
  alias Blessd.Observance.Meetings.Occurrences.Occurrence
  alias Blessd.Repo
  alias Blessd.Shared

  @doc false
  def list(user, opts) do
    opts = Keyword.merge([filter: []], opts)

    with {:ok, query} <- Shared.authorize(Occurrence, user) do
      query
      |> preload()
      |> apply_filter(opts[:filter])
      |> order()
      |> Repo.list()
    end
  end

  @doc false
  def find(id, current_user) do
    with {:ok, query} <- Shared.authorize(Occurrence, current_user) do
      query
      |> preload()
      |> Repo.find(id)
    end
  end

  @doc false
  def create(%Meeting{} = meeting, attrs, current_user) do
    insert(Repo, meeting, attrs, current_user)
  end

  @doc false
  def insert(repo, %{meeting: meeting}, attrs, current_user) do
    insert(repo, meeting, attrs, current_user)
  end

  def insert(repo, %Meeting{id: meeting_id}, attrs, current_user) do
    current_user
    |> build(meeting_id, nil)
    |> Occurrence.changeset(attrs)
    |> repo.insert()
  end

  @doc false
  def update(id, attrs, current_user) do
    with {:ok, occurrence} <- find(id, current_user),
         {:ok, occurrence} <- Shared.authorize(occurrence, current_user) do
      occurrence
      |> Occurrence.changeset(attrs)
      |> Repo.update()
    end
  end

  @doc false
  def delete(id, current_user) do
    with {:ok, occurrence} <- find(id, current_user),
         {:ok, occurrence} <- Shared.authorize(occurrence, current_user) do
      Repo.delete(occurrence)
    end
  end

  @doc false
  def new_changeset(meeting_id, current_user) do
    with {:ok, occurrence} <-
           current_user
           |> build(meeting_id)
           |> Shared.authorize(current_user) do
      {:ok, Occurrence.changeset(occurrence, %{})}
    end
  end

  @doc false
  def edit_changeset(id, current_user) do
    with {:ok, occurrence} <- find(id, current_user),
         {:ok, occurrence} <- Shared.authorize(occurrence, current_user) do
      {:ok, Occurrence.changeset(occurrence, %{})}
    end
  end

  @doc false
  def build(current_user, meeting_id \\ nil, date \\ nil) do
    %Occurrence{
      church_id: current_user.church.id,
      meeting_id: meeting_id,
      date: date || Blessd.Date.today(current_user)
    }
  end

  @doc false
  def preload(query) do
    query
    |> join(:inner, [o], m in assoc(o, :meeting), as: :meeting)
    |> preload([o, meeting: m], meeting: m)
  end

  @doc false
  def order(query) do
    if has_named_binding?(query, :meeting) do
      order_by(query, [o, meeting: m], asc: m.name, desc: o.date)
    else
      order_by(query, [o], desc: o.date)
    end
  end

  @doc false
  def apply_filter(query, []), do: query

  def apply_filter(query, [{:date, date} | tail]) do
    query
    |> where([o], o.date == ^date)
    |> apply_filter(tail)
  end

  def apply_filter(query, [_ | tail]) do
    apply_filter(query, tail)
  end
end
