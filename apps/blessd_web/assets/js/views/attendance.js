import Mousetrap from "mousetrap"
import BlessdSocket from "../socket"

export default class AttendanceView {
  constructor() {
    this.socket = new BlessdSocket();
    this.channel = this.socket.channel("attendance:lobby", {});
    this.searchEl = document.querySelector(".js-search");
    this.nameEl = document.getElementById("person_name");
    this.tableEl = document.querySelector(".js-people");
    this.tableBodyEl = this.tableEl.querySelector(".js-people-body");
  }

  index() {
    this.socket.connect();
    this.channel.join()
      .receive("ok", _ => {
        console.info("Joined channel successfully")

        this.addSearchListener();
        this.bindKeys();
        this.bindRowHover();
        this.bindRowClick();
      })
      .receive("error", resp => console.error("Unable to join", resp));
  }

  getStateFromButton(button) {
    if (button.classList.contains("js-person-unknown")) return "unknown";
    if (button.classList.contains("js-person-present")) return "present";
    if (button.classList.contains("js-person-absent")) return "absent";
    return;
  }

  updateState(row, occurrenceId, state) {
    this.channel
      .push("update_state", {
        person_id: row.getAttribute("data-id"),
        meeting_occurrence_id: occurrenceId,
        state: state
      })
      .receive("ok", resp => row.innerHTML = resp.table_row)
      .receive("error", reason => console.error("Unable to update attendant state", reason))
      .receive("timeout", _ => console.error("Networking issue..."));
  }

  addSearchListener() {
    this.searchEl.addEventListener("keydown", event => {
      if ([13, 38, 40].includes(event.keyCode)) event.preventDefault();
    });

    this.searchEl.addEventListener("keyup", event => {
      if (![13, 38, 40].includes(event.keyCode)) {
        const occurrenceId = this.tableBodyEl.getAttribute("data-occurrence-id");

        this.nameEl.value = this.searchEl.value;

        this.channel
          .push("search", {
            meeting_occurrence_id: occurrenceId,
            query: this.searchEl.value
          })
          .receive("ok", resp => {
            this.tableBodyEl.innerHTML = resp.table_body;
            this.selectRow(0);

            // needs to be rebound because it depends on the inner content
            this.bindRowHover();
          })
          .receive("error", reason => console.error("Unable to search people", reason))
          .receive("timeout", _ => console.error("Networking issue..."));
          }
    })
  }

  keyUp() {
    const row = this.getRow();
    if (row) {
      const prev = row.previousElementSibling;
      if (prev) {
        row.classList.remove("nav-focus");
        prev.classList.add("nav-focus");
      }
    } else {
      this.selectRow(this.tableBodyEl.children.length-1);
    }
  }

  keyDown() {
    const row = this.getRow();
    if (row) {
      const next = row.nextElementSibling;
      if (next) {
        row.classList.remove("nav-focus");
        next.classList.add("nav-focus");
      }
    } else {
      this.selectRow(0);
    }
  }

  keyEnter() {
    const row = this.getRow();
    const occurrenceId = this.tableBodyEl.getAttribute("data-occurrence-id");
    if (row) {
      this.toggleRow(row, occurrenceId);
    } else {
      document.getElementById("visitor_modal").classList.add("is-active");
    }
  }

  bindKeys() {
    const mousetrap = new Mousetrap(document.body);
    mousetrap.bind("up", _ => this.keyUp());
    mousetrap.bind("down", _ => this.keyDown());
    mousetrap.bind("enter", _ => this.keyEnter());
  }

  bindRowHover() {
    const rows = this.tableBodyEl.querySelectorAll(".js-person");

    for (let row of rows) {
      row.addEventListener("mouseenter", event => {
        const selectedRow = this.getRow();
        if (selectedRow) selectedRow.classList.remove("nav-focus");
        event.target.classList.add("nav-focus");
      });
    }
  }

  selectRow(index) {
    const row = this.getRow();
    if (row) row.classList.remove("nav-focus");

    const firstRow = this.tableBodyEl.children[index];
    if (firstRow) firstRow.classList.add("nav-focus");
  }

  getRow() {
    return this.tableBodyEl.querySelector(".nav-focus");
  }

  bindRowClick() {
    this.tableBodyEl.addEventListener("click", event => {
      const parentButton = this.parentsQuerySelector(event.target, "js-person-button");
      const row = this.parentsQuerySelector(event.target, "js-person");
      if (parentButton) {
        this.updateState(
          row,
          this.tableBodyEl.getAttribute("data-occurrence-id"),
          this.getStateFromButton(parentButton)
        );
      } else {
        const occurrenceId = this.tableBodyEl.getAttribute("data-occurrence-id");
        this.toggleRow(row, occurrenceId)
      }
    });
  }

  parentsQuerySelector(target, className) {
    if (target == null) return null;
    if (target.classList.contains(className)) return target;

    return this.parentsQuerySelector(target.parentElement, className);
  }

  toggleRow(tr, occurrenceId) {
    const unknown = tr.querySelector(".js-person-unknown");
    const present = tr.querySelector(".js-person-present");
    const absent = tr.querySelector(".js-person-absent");

    if (unknown.classList.contains("is-warning")) {
      return this.updateState(
        tr,
        occurrenceId,
        "present"
      );
    }

    if (present.classList.contains("is-success")) {
      return this.updateState(
        tr,
        occurrenceId,
        "absent"
      );
    }

    if (absent.classList.contains("is-danger")) {
      return this.updateState(
        tr,
        occurrenceId,
        "unknown"
      );
    }

    return;
  }
}
