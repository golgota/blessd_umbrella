defmodule BlessdWeb.AttendanceChannelTest do
  use BlessdWeb.ChannelCase

  alias BlessdWeb.AttendanceChannel

  alias Blessd.Accounts
  alias Blessd.Auth.Church
  alias Blessd.Memberships
  alias Blessd.Observance

  setup do
    {:ok, church_account} = Accounts.create_church(%{name: "church 1", identifier: "church1"})

    church_attrs =
      church_account
      |> Map.from_struct()
      |> Map.take(Map.keys(%Church{}))

    church = struct!(Church, church_attrs)

    {:ok, _person} = Memberships.create_person(%{name: "person 1", is_member: true}, church)
    {:ok, _person} = Memberships.create_person(%{name: "person 2", is_member: false}, church)

    {:ok, service} =
      Observance.create_service(
        %{
          name: "some name",
          date: ~D[2005-09-23]
        },
        church
      )

    service = Observance.get_service!(service.id, church)
    attendants = Observance.list_attendants(service, church)

    {:ok, _, socket} =
      socket("user_id", %{current_church: church})
      |> subscribe_and_join(AttendanceChannel, "attendance:lobby")

    {:ok, socket: socket, service: service, attendants: attendants}
  end

  test "search replies with html", %{socket: socket, service: service} do
    ref = push(socket, "search", %{"service_id" => service.id, "query" => "bla"})
    assert_reply(ref, :ok, %{table_body: ""})

    ref = push(socket, "search", %{"service_id" => service.id, "query" => "1"})
    assert_reply(ref, :ok, %{table_body: body})
    assert String.contains?(body, "person 1")
    refute String.contains?(body, "person 2")
  end

  test "update replies with ok", %{socket: socket, service: service, attendants: attendants} do
    attendant = List.first(attendants)
    assert attendant.is_present == false
    ref = push(socket, "update", %{"id" => attendant.id, "attendant" => %{"is_present" => true}})
    assert_reply(ref, :ok)

    ref = push(socket, "search", %{"service_id" => service.id, "query" => "1"})
    assert_reply(ref, :ok, %{table_body: body})
    assert String.contains?(body, "person 1")
    assert String.contains?(body, "checked")

    ref = push(socket, "search", %{"service_id" => service.id, "query" => "2"})
    assert_reply(ref, :ok, %{table_body: body})
    assert String.contains?(body, "person 2")
    refute String.contains?(body, "checked")
  end
end
