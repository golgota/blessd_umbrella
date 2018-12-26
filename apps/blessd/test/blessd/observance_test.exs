defmodule Blessd.ObservanceTest do
  use Blessd.DataCase

  alias Blessd.Observance

  describe "meetings" do
    alias Blessd.Observance.Meetings.Meeting

    @valid_attrs %{"name" => "some name", "occurrences" => %{"0" => %{date: ~D[2018-10-10]}}}
    @update_attrs %{"name" => "updated name", "occurrences" => %{"0" => %{date: ~D[2000-01-01]}}}
    @invalid_attrs %{name: nil}

    def meeting_fixture(attrs \\ %{}, user) do
      {:ok, meeting} =
        attrs
        |> Enum.into(@valid_attrs)
        |> Observance.create_meeting(user)

      meeting
    end

    test "list_meetings/0 returns all meetings" do
      user = signup()
      meeting = meeting_fixture(user)
      assert {:ok, [found]} = Observance.list_meetings(user)

      assert found.name == meeting.name
    end

    test "find_meeting/1 returns the meeting with given id" do
      user = signup()
      meeting = meeting_fixture(user)
      assert {:ok, found} = Observance.find_meeting(meeting.id, user)

      assert found.name == meeting.name
    end

    test "create_meeting/1 with valid data creates a meeting" do
      user = signup()
      assert {:ok, %Meeting{} = meeting} = Observance.create_meeting(@valid_attrs, user)
      assert meeting.name == "some name"
    end

    test "create_meeting/1 with invalid data returns error changeset" do
      user = signup()
      assert {:error, %Ecto.Changeset{}} = Observance.create_meeting(@invalid_attrs, user)
    end

    test "update_meeting/2 with valid data updates the meeting" do
      user = signup()
      meeting = meeting_fixture(user)

      assert {:ok, %Meeting{} = meeting} =
               Observance.update_meeting(meeting.id, @update_attrs, user)

      assert meeting.name == "updated name"
    end

    test "update_meeting/2 with invalid data returns error changeset" do
      user = signup()
      meeting = meeting_fixture(user)

      assert {:error, %Ecto.Changeset{}} =
               Observance.update_meeting(meeting.id, @invalid_attrs, user)

      assert {:ok, found} = Observance.find_meeting(meeting.id, user)

      assert found.name == meeting.name
    end

    test "delete_meeting/1 deletes the meeting" do
      user = signup()
      meeting = meeting_fixture(user)
      assert {:ok, %Meeting{}} = Observance.delete_meeting(meeting.id, user)
      assert {:error, :not_found} == Observance.find_meeting(meeting.id, user)
    end
  end
end
