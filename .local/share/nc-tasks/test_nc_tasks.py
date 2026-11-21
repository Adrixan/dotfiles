"""Tests for ~/.local/bin/nc-tasks: python3 -I ~/.local/share/nc-tasks/test_nc_tasks.py"""
from __future__ import annotations

import importlib.machinery
import importlib.util
import io
import json
import sys
import unittest
import urllib.error
from datetime import datetime, timezone
from email.message import Message
from pathlib import Path
from typing import Any

PATH = Path.home() / ".local/bin/nc-tasks"
loader = importlib.machinery.SourceFileLoader("nc_tasks", str(PATH))
spec = importlib.util.spec_from_loader("nc_tasks", loader)
assert spec is not None
N = importlib.util.module_from_spec(spec)
sys.modules["nc_tasks"] = N
loader.exec_module(N)

ENV = {"NEXTCLOUD_HOST": "https://cloud.example", "NEXTCLOUD_USERNAME": "peter", "NEXTCLOUD_PASSWORD": "s3cret-pw"}
BASE = "/remote.php/dav/calendars/peter/tasks/"
NOW = datetime(2026, 11, 21, 9, 0, tzinfo=timezone.utc)
CFG = N.Config(default_list="tasks", timezone="Europe/Vienna", guard_list="tasks", guard_parent="Aspirations")


def vtodo(uid: str, summary: str, parent: str = "", extra: tuple[str, ...] = ()) -> str:
    lines = ["BEGIN:VCALENDAR", "VERSION:2.0", "PRODID:-//test//EN", "BEGIN:VTODO", f"UID:{uid}", f"SUMMARY:{summary}",
             "DTSTAMP:20261116T120000Z", "CREATED:20261116T120000Z", "X-KEEP-ME;X-P=1:value\\, kept", "SEQUENCE:2"]
    if parent:
        lines.append(f"RELATED-TO:{parent}")
    lines += [*extra, "BEGIN:VALARM", "ACTION:DISPLAY", "DESCRIPTION:alarm text", "TRIGGER:-PT15M", "END:VALARM",
              "END:VTODO", "END:VCALENDAR"]
    return "\r\n".join(lines) + "\r\n"


class Resp:
    def __init__(self, status: int, body: str = "") -> None:
        self.status, self.headers, self._body = status, Message(), body.encode()

    def read(self) -> bytes:
        return self._body

    def __enter__(self) -> Resp:
        return self

    def __exit__(self, *a: object) -> None:
        return None


class FakeServer:
    """A minimal CalDAV list: REPORT, PROPFIND, PUT (If-Match / If-None-Match), DELETE."""

    def __init__(self, items: dict[str, str]) -> None:
        self.items = {f"{BASE}{uid}.ics": (ics, f'"e{i}"') for i, (uid, ics) in enumerate(items.items())}
        self.calls: list[tuple[str, str, dict[str, str], bytes]] = []
        self.n = 100

    def __call__(self, req: Any, timeout: int = 60) -> Resp:
        url, method = req.full_url, req.get_method()
        headers = {k.title(): v for k, v in req.header_items()}
        body = req.data or b""
        self.calls.append((method, url, headers, body))
        path = url.removeprefix(ENV["NEXTCLOUD_HOST"])
        if method == "REPORT":
            parts = "".join(f"<d:response><d:href>{h}</d:href><d:propstat><d:prop><d:getetag>{e}</d:getetag>"
                            f"<c:calendar-data><![CDATA[{ics}]]></c:calendar-data></d:prop></d:propstat></d:response>"
                            for h, (ics, e) in self.items.items())
            return Resp(207, f'<d:multistatus xmlns:d="DAV:" xmlns:c="urn:ietf:params:xml:ns:caldav">{parts}</d:multistatus>')
        if method == "PROPFIND":
            return Resp(207, '<d:multistatus xmlns:d="DAV:" xmlns:c="urn:ietf:params:xml:ns:caldav">'
                             '<d:response><d:href>/remote.php/dav/calendars/peter/tasks/</d:href><d:propstat><d:prop>'
                             '<d:displayname>Tasks</d:displayname><d:resourcetype><d:collection/><c:calendar/></d:resourcetype>'
                             '<c:supported-calendar-component-set><c:comp name="VTODO"/></c:supported-calendar-component-set>'
                             '</d:prop></d:propstat></d:response>'
                             '<d:response><d:href>/remote.php/dav/calendars/peter/personal/</d:href><d:propstat><d:prop>'
                             '<d:displayname>Personal</d:displayname><d:resourcetype><c:calendar/></d:resourcetype>'
                             '<c:supported-calendar-component-set><c:comp name="VEVENT"/></c:supported-calendar-component-set>'
                             '</d:prop></d:propstat></d:response></d:multistatus>')
        if method == "PUT":
            if headers.get("If-None-Match") == "*" and path in self.items:
                raise urllib.error.HTTPError(url, 412, "exists", Message(), io.BytesIO(b""))
            if "If-Match" in headers and (path not in self.items or self.items[path][1] != headers["If-Match"]):
                raise urllib.error.HTTPError(url, 412, "etag", Message(), io.BytesIO(b""))
            self.n += 1
            self.items[path] = (body.decode(), f'"e{self.n}"')
            return Resp(201)
        if method == "DELETE":
            if path not in self.items or self.items[path][1] != headers.get("If-Match"):
                raise urllib.error.HTTPError(url, 412, "etag", Message(), io.BytesIO(b""))
            del self.items[path]
            return Resp(204)
        raise AssertionError(method)

    def writes(self) -> list[tuple[str, str, dict[str, str], bytes]]:
        return [c for c in self.calls if c[0] in ("PUT", "DELETE")]

    def ics(self, uid: str) -> str:
        return self.items[f"{BASE}{uid}.ics"][0]


def run(server: FakeServer, *argv: str) -> tuple[int, str, str]:
    out, err = io.StringIO(), io.StringIO()
    code = N.main(list(argv), out=out, err=err, opener=server, env=dict(ENV), cfg=CFG, now=NOW)
    return code, out.getvalue(), err.getvalue()


def world() -> FakeServer:
    return FakeServer({
        "asp": vtodo("asp", "Aspirations"),
        "idea": vtodo("idea", "Gutscheinmanagement App", "asp", ("PRIORITY:3",)),
        "milk": vtodo("milk", "Buy milk"),
        "dup1": vtodo("dup1", "Call Julia"),
        "dup2": vtodo("dup2", "call julia"),
        "home": vtodo("home", "Home", extra=("DTSTART;VALUE=DATE:20261120",)),
    })


class Escaping(unittest.TestCase):
    def test_text_roundtrip(self) -> None:
        raw = "a, b; c\\d\r\nline two"
        line = N.new_vtodo("u", raw, NOW, note=raw, categories=["x,y", "z;w"])
        todo = N.asp.parse_todos(line)[0]
        self.assertEqual(todo.summary, "a, b; c\\d\nline two")
        self.assertEqual(todo.description, "a, b; c\\d\nline two")
        self.assertEqual(todo.categories, ["x,y", "z;w"])
        self.assertIn("SUMMARY:a\\, b\\; c\\\\d\\nline two", line)

    def test_long_lines_fold(self) -> None:
        ics = N.new_vtodo("u", "x" * 200, NOW)
        self.assertTrue(all(len(line.encode()) <= 75 for line in ics.split("\r\n")))
        self.assertEqual(N.asp.parse_todos(ics)[0].summary, "x" * 200)

    def test_due(self) -> None:
        tz = N.ZoneInfo("Europe/Vienna")
        self.assertEqual(N.due_line("2026-11-30", tz), ("DUE;VALUE=DATE:20261130", True))
        self.assertEqual(N.due_line("2026-11-30T18:00", tz), ("DUE:20261130T170000Z", False))
        self.assertEqual(N.due_line("2026-07-01T18:00", tz), ("DUE:20260701T160000Z", False))
        self.assertEqual(N.show_due({}, "20261130T170000Z", tz), "2026-11-30T18:00")
        with self.assertRaises(N.Fail):
            N.due_line("30.11.2026", tz)
        with self.assertRaises(N.Fail):
            N.due_line("2026-02-30", tz)


class Commands(unittest.TestCase):
    def test_lists(self) -> None:
        code, out, _ = run(world(), "lists")
        self.assertEqual(code, 0)
        self.assertEqual(out, "tasks\tTasks (default)\n")

    def test_list_tree_and_json(self) -> None:
        code, out, _ = run(world(), "list")
        self.assertEqual(code, 0)
        self.assertIn("[ ]    -                Aspirations  <asp>\n  [ ] P3 -                Gutscheinmanagement App  <idea>", out)
        code, out, _ = run(world(), "list", "--json", "--parent", "Aspirations")
        data = json.loads(out)
        self.assertEqual([d["uid"] for d in data], ["asp"])
        self.assertEqual(data[0]["children"][0]["priority"], 3)

    def test_add_writes_full_vtodo(self) -> None:
        s = world()
        code, out, err = run(s, "add", "Pay, rent; now", "--due", "2026-12-01T09:30", "--priority", "2",
                             "--note", "line1\nline2", "--parent", "Buy milk", "--category", "home")
        self.assertEqual((code, err), (0, ""))
        method, url, headers, body = s.writes()[0]
        self.assertEqual(headers["If-None-Match"], "*")
        todo = N.asp.parse_todos(body.decode())[0]
        self.assertEqual((todo.summary, todo.priority, todo.parent, todo.categories), ("Pay, rent; now", 2, "milk", ["home"]))
        self.assertIn("DUE:20261201T083000Z", body.decode())
        self.assertIn(f"added {todo.uid} to tasks", out)

    def test_dry_run_changes_nothing(self) -> None:
        s = world()
        for argv in (("add", "x", "--dry-run"), ("done", "Buy milk", "-n"), ("edit", "milk", "--priority", "1", "-n"),
                     ("delete", "milk", "--dry-run")):
            code, out, _ = run(s, *argv)
            self.assertEqual(code, 0, argv)
            self.assertTrue(out.startswith("dry run"), argv)
        self.assertEqual(s.writes(), [])

    def test_done_keeps_other_properties(self) -> None:
        s = world()
        code, out, _ = run(s, "done", "BUY MILK")
        self.assertEqual(code, 0)
        _, _, headers, body = s.writes()[0]
        self.assertEqual(headers["If-Match"], '"e2"')
        ics = body.decode()
        for keep in ("X-KEEP-ME;X-P=1:value\\, kept", "DESCRIPTION:alarm text", "TRIGGER:-PT15M", "CREATED:20261116T120000Z"):
            self.assertIn(keep, ics)
        self.assertIn("STATUS:COMPLETED", ics)
        self.assertIn("PERCENT-COMPLETE:100", ics)
        self.assertIn("SEQUENCE:3", ics)
        self.assertEqual(ics.count("DTSTAMP:"), 1)
        self.assertNotIn("20261116T120000Z\r\nDTSTAMP", ics)
        code, _, err = run(s, "done", "Buy milk")
        self.assertEqual(code, N.EXIT_NOT_FOUND)  # done tasks are not matched by title again

    def test_edit_note_due_priority(self) -> None:
        s = world()
        self.assertEqual(run(s, "edit", "milk", "--note", "first")[0], 0)
        self.assertEqual(run(s, "edit", "milk", "--append-note", "second, more")[0], 0)
        self.assertEqual(run(s, "edit", "milk", "--priority", "4", "--due", "2026-12-24")[0], 0)
        todo = N.asp.parse_todos(s.ics("milk"))[0]
        self.assertEqual((todo.description, todo.priority), ("first\nsecond, more", 4))
        self.assertIn("DESCRIPTION:alarm text", s.ics("milk"))  # the VALARM's DESCRIPTION is not the note
        self.assertIn("DUE;VALUE=DATE:20261224", s.ics("milk"))
        self.assertEqual(run(s, "edit", "milk", "--priority", "0", "--due", "none")[0], 0)
        self.assertNotIn("PRIORITY", s.ics("milk"))
        self.assertNotIn("\r\nDUE", s.ics("milk"))
        self.assertEqual(run(s, "edit", "milk")[0], N.EXIT_USAGE)
        self.assertEqual(run(s, "edit", "home", "--due", "2026-12-24T10:00")[0], N.EXIT_USAGE)  # DTSTART is a date

    def test_ambiguous_and_missing(self) -> None:
        code, _, err = run(world(), "done", "Call Julia")
        self.assertEqual(code, N.EXIT_AMBIGUOUS)
        self.assertIn("dup1", err)
        self.assertEqual(run(world(), "done", "dup2")[0], 0)
        self.assertEqual(run(world(), "done", "nothing here")[0], N.EXIT_NOT_FOUND)
        self.assertEqual(run(world(), "delete", "Buy milk")[0], N.EXIT_NOT_FOUND)  # delete takes UIDs only

    def test_aspirations_guard(self) -> None:
        s = world()
        for argv in (("edit", "Gutscheinmanagement App", "--priority", "1"), ("done", "idea"), ("edit", "Aspirations", "--note", "x"),
                     ("add", "new idea", "--parent", "Aspirations"), ("delete", "idea")):
            code, _, err = run(s, *argv)
            self.assertEqual(code, N.EXIT_REFUSED, argv)
            self.assertIn("--allow-aspirations", err)
        self.assertEqual(s.writes(), [])
        self.assertEqual(run(s, "edit", "idea", "--priority", "2", "--allow-aspirations")[0], 0)
        self.assertEqual(N.asp.parse_todos(s.ics("idea"))[0].priority, 2)
        other = N.Config(default_list="packliste", guard_list="tasks", guard_parent="Aspirations")
        o2, e2 = io.StringIO(), io.StringIO()
        s2 = world()
        s2.items = {k.replace("/tasks/", "/packliste/"): v for k, v in s2.items.items()}
        code = N.main(["done", "idea"], out=o2, err=e2, opener=s2, env=dict(ENV), cfg=other, now=NOW)
        self.assertEqual(code, 0)  # the guard covers only the aspirations list

    def test_conflict(self) -> None:
        s = world()
        real = s.__call__

        def racing(req: Any, timeout: int = 60) -> Resp:
            if req.get_method() == "PUT":
                path = req.full_url.removeprefix(ENV["NEXTCLOUD_HOST"])
                s.items[path] = (s.items[path][0], '"changed"')
            return real(req, timeout)
        out, err = io.StringIO(), io.StringIO()
        code = N.main(["done", "milk"], out=out, err=err, opener=racing, env=dict(ENV), cfg=CFG, now=NOW)
        self.assertEqual(code, N.EXIT_CONFLICT)

    def test_delete_refuses_parent(self) -> None:
        s = world()
        self.assertEqual(run(s, "delete", "asp", "--allow-aspirations")[0], N.EXIT_REFUSED)
        self.assertEqual(run(s, "delete", "milk")[0], 0)
        self.assertNotIn(f"{BASE}milk.ics", s.items)

    def test_safety(self) -> None:
        bad = dict(ENV, NEXTCLOUD_HOST="http://cloud.example")
        out, err = io.StringIO(), io.StringIO()
        self.assertEqual(N.main(["list"], out=out, err=err, opener=world(), env=bad, cfg=CFG, now=NOW), N.EXIT_FAIL)
        self.assertIn("https", err.getvalue())
        self.assertEqual(run(world(), "list", "--list", "../etc")[0], N.EXIT_USAGE)
        self.assertEqual(run(world(), "add", "x", "--priority", "12")[0], N.EXIT_USAGE)
        s = world()
        for argv in (("list",), ("add", "x"), ("done", "Call Julia"), ("edit", "idea", "--note", "x")):
            _, sout, serr = run(s, *argv)
            self.assertNotIn("s3cret-pw", sout + serr)
        with self.assertRaises(N.Fail):
            N.Client(ENV, "tasks", s)._url("/remote.php/dav/calendars/peter/other/x.ics")


if __name__ == "__main__":
    unittest.main(verbosity=1)
