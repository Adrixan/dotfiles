"""Tests for ~/.local/bin/aspirations: python3 -I ~/.local/share/aspirations/test_aspirations.py"""
from __future__ import annotations

import importlib.machinery
import importlib.util
import subprocess
import sys
import tempfile
import unittest
from datetime import datetime, timezone
from pathlib import Path

PATH = Path.home() / ".local/bin/aspirations"
loader = importlib.machinery.SourceFileLoader("aspirations", str(PATH))
spec = importlib.util.spec_from_loader("aspirations", loader)
A = importlib.util.module_from_spec(spec)
sys.modules["aspirations"] = A
loader.exec_module(A)


def vtodo(uid: str, summary: str, parent: str = "", **props: str) -> str:
    lines = ["BEGIN:VCALENDAR", "VERSION:2.0", "PRODID:-//test//EN", "BEGIN:VTODO", f"UID:{uid}",
             f"SUMMARY:{summary}", f"CREATED:{props.pop('created', '20261116T120000Z')}", "DTSTAMP:20261116T120000Z"]
    if parent:
        lines.append(f"RELATED-TO:{parent}")
    lines += [f"{k.replace('_', '-').upper()}:{v}" for k, v in props.items()]
    lines += ["END:VTODO", "END:VCALENDAR"]
    return "\r\n".join(lines) + "\r\n"


def todos(*objs: str) -> list:
    out = []
    for i, o in enumerate(objs):
        out += A.parse_todos(o, f"/remote.php/dav/calendars/u/tasks/{i}.ics", f'"e{i}"')
    return out


class Ics(unittest.TestCase):
    def test_fold_unfold_roundtrip(self) -> None:
        long = "DESCRIPTION:" + "Gutschein mit Ümlauten äöü " * 10
        folded = A.fold(long)
        self.assertTrue(all(len(x.encode()) <= 75 for x in folded.split("\r\n")))
        self.assertEqual(A.unfold(folded)[0], long)

    def test_parse_fields_and_escapes(self) -> None:
        t = A.parse_todos(vtodo("u1", "Idee\\, gross", "p", priority="3", description="a\\nb\\; c",
                                categories="research,model:fable-5.2", status="needs-action"))[0]
        self.assertEqual((t.summary, t.description, t.priority, t.parent, t.status), ("Idee, gross", "a\nb; c", 3, "p", "NEEDS-ACTION"))
        self.assertEqual(t.categories, ["research", "model:fable-5.2"])

    def test_reltype_child_is_not_parent(self) -> None:
        obj = vtodo("u1", "x").replace("END:VTODO", "RELATED-TO;RELTYPE=CHILD:other\r\nEND:VTODO")
        self.assertEqual(A.parse_todos(obj)[0].parent, "")

    def test_mark_started(self) -> None:
        obj = vtodo("u1", "Idee", "p", description="Note", categories="web", sequence="2", status="NEEDS-ACTION")
        now = datetime(2026, 11, 22, 4, 0, tzinfo=timezone.utc)
        new = A.mark_started(obj, "u1", "aspiration-started", "[aspirations] started, ok; role x", now)
        t = A.parse_todos(new)[0]
        self.assertEqual(t.status, "IN-PROCESS")
        self.assertEqual(t.categories, ["web", "aspiration-started"])
        self.assertEqual(t.description, "Note\n\n[aspirations] started, ok; role x")
        self.assertIn("SEQUENCE:3", new)
        self.assertIn("LAST-MODIFIED:20261122T040000Z", new)
        self.assertEqual(new.count("STATUS:"), 1)
        self.assertTrue(new.endswith("END:VCALENDAR\r\n"))

    def test_mark_started_adds_missing_props_and_leaves_other_todos(self) -> None:
        obj = vtodo("u1", "Idee", "p").replace("END:VCALENDAR", "BEGIN:VTODO\r\nUID:u2\r\nSUMMARY:other\r\nEND:VTODO\r\nEND:VCALENDAR")
        new = A.mark_started(obj, "u1", "aspiration-started", "n", datetime.now(timezone.utc))
        by = {t.uid: t for t in A.parse_todos(new)}
        self.assertEqual((by["u1"].status, by["u1"].categories, by["u1"].description), ("IN-PROCESS", ["aspiration-started"], "n"))
        self.assertEqual((by["u2"].status, by["u2"].categories), ("", []))


class Selection(unittest.TestCase):
    def setUp(self) -> None:
        self.cfg = A.Config()

    def test_priority_then_oldest(self) -> None:
        ts = todos(vtodo("p", "Aspirations"),
                   vtodo("a", "none", "p"),
                   vtodo("b", "low", "p", priority="9"),
                   vtodo("c", "high new", "p", priority="1", created="20261120T000000Z"),
                   vtodo("d", "high old", "p", priority="1", created="20261110T000000Z"),
                   vtodo("e", "child of d", "d", priority="1", created="20260101T000000Z"))
        _, rows = A.plan(ts, self.cfg, set())
        order = [t.summary for t, ok, _ in rows if ok]
        self.assertEqual(order, ["high old", "high new", "low", "none"])

    def test_skips(self) -> None:
        ts = todos(vtodo("p", "aspirations"),
                   vtodo("a", "done", "p", priority="1", status="COMPLETED"),
                   vtodo("b", "busy", "p", priority="1", status="IN-PROCESS"),
                   vtodo("c", "cancelled", "p", priority="1", status="CANCELLED"),
                   vtodo("d", "half", "p", priority="1", percent_complete="50"),
                   vtodo("e", "tagged", "p", priority="1", categories="Aspiration-Started"),
                   vtodo("f", "local", "p", priority="1"),
                   vtodo("g", "completed prop", "p", priority="1", completed="20261101T000000Z"),
                   vtodo("h", "free", "p", priority="5"))
        _, rows = A.plan(ts, self.cfg, {"f"})
        self.assertEqual([t.summary for t, ok, _ in rows if ok], ["free"])

    def test_parent_missing_or_ambiguous(self) -> None:
        with self.assertRaises(RuntimeError):
            A.plan(todos(vtodo("x", "Other")), self.cfg, set())
        with self.assertRaises(RuntimeError):
            A.plan(todos(vtodo("x", "Aspirations"), vtodo("y", "Aspirations")), self.cfg, set())

    def test_subtree_in_brief(self) -> None:
        ts = todos(vtodo("p", "Aspirations"), vtodo("i", "Idee", "p", description="Note"),
                   vtodo("s1", "Step one", "i", description="detail"), vtodo("s2", "Step two", "i", status="COMPLETED"),
                   vtodo("s3", "Sub step", "s1"))
        route = A.Route("code-new", "idee", ["--ttl", "12h"])
        brief = A.build_brief(ts[1], ts, route, self.cfg, datetime(2026, 11, 22, 5, 0))
        self.assertIn("- [ ] Step one (status open)", brief)
        self.assertIn("  > detail", brief)
        self.assertIn("  - [ ] Sub step", brief)
        self.assertIn("- [x] Step two (status completed)", brief)
        self.assertIn("rc handoff-done --stop", brief)
        self.assertIn("Open decisions", brief)
        self.assertIn("never deploy but create concepts and prototypes", brief)
        self.assertIn("Never deploy or publish anything", brief)
        self.assertIn("architectural requirements stated in the note", brief)
        self.assertIn("state the task asks for at start time", brief)
        self.assertIn("state as the job read it from the task list at start time", brief)
        self.assertNotIn("publishing or deploying anywhere", brief)


class Routing(unittest.TestCase):
    def setUp(self) -> None:
        self.tmp = tempfile.TemporaryDirectory()
        root = Path(self.tmp.name)
        for d in ("code/existing-app", "projects/BIMM", "projects/Music", "confs"):
            (root / d).mkdir(parents=True)
        (root / "confs/bimm.conf").write_text(f'# x\nRC_DIR="{root}/projects/BIMM"\nRC_NAME="BIMM"\n')
        self.cfg = A.Config(code_dir=str(root / "code"), projects_dir=str(root / "projects"), rc_conf_dir=str(root / "confs"))

    def tearDown(self) -> None:
        self.tmp.cleanup()

    def idea(self, summary: str, cats: str = "") -> object:
        return A.parse_todos(vtodo("i", summary, "p", **({"categories": cats} if cats else {})))[0]

    def test_slug(self) -> None:
        self.assertEqual(A.slugify("Gutscheinmanagement App"), "gutscheinmanagement-app")
        self.assertEqual(A.slugify("Übersicht für Größen!"), "uebersicht-fuer-groessen")
        self.assertLessEqual(len(A.slugify("x" * 80)), 35)

    def test_routes(self) -> None:
        r = A.route_for(self.idea("New Thing"), self.cfg)
        self.assertEqual((r.kind, r.target, r.role()), ("code-new", "new-thing", "code-new-thing"))
        self.assertEqual(r.command("/rc"), ["/rc", "code", "--new", "new-thing", "--ttl", "12h", "--brief", "-"])
        r = A.route_for(self.idea("Existing App"), self.cfg)
        self.assertEqual((r.kind, r.target, r.args[0]), ("code", "existing-app", "--fresh"))
        self.assertEqual(A.route_for(self.idea("Research", "project"), self.cfg).kind, "project")
        r = A.route_for(self.idea("Whatever", "code:existing-app,model:fable-5.2"), self.cfg)
        self.assertEqual((r.kind, r.target, r.args[-2:]), ("code", "existing-app", ["--model", "fable-5.2"]))
        r = A.route_for(self.idea("Solarpunk energy markets", "research"), self.cfg)
        self.assertEqual(r.command("/rc")[:3], ["/rc", "research", "Solarpunk energy markets"])
        r = A.route_for(self.idea("Garten: Plan / Saison 2027!", "project"), self.cfg)
        self.assertEqual(r.command("/rc"), ["/rc", "project", "Garten Plan Saison 2027", "--ttl", "12h", "--brief", "-"])
        self.assertEqual(r.role(), "project-garten-plan-saison-2027")
        r = A.route_for(self.idea("Whatever", "vault:bimm,model:sonnet-5.5"), self.cfg)
        self.assertEqual((r.target, r.role(), r.args[-2:]), ("bimm", "bimm", ["--model", "sonnet-5.5"]))
        r = A.route_for(self.idea("Übungsheft Größen", "project"), self.cfg)
        self.assertEqual(r.target, "Übungsheft Größen")
        self.assertEqual(A.route_for(self.idea("x", "project:Music"), self.cfg).role(), "project-music")
        with self.assertRaises(RuntimeError):
            A.route_for(self.idea("!!!", "project"), self.cfg)
        with self.assertRaises(RuntimeError):
            A.route_for(self.idea("x", "code:../etc"), self.cfg)
        with self.assertRaises(RuntimeError):
            A.route_for(self.idea("x", "code:missing"), self.cfg)


class FakeRun:
    def __init__(self, results: list[tuple[int, str]]):
        self.results, self.calls = list(results), []

    def __call__(self, cmd, **kw):
        self.calls.append((cmd, kw.get("input")))
        rc, out = self.results.pop(0)
        return subprocess.CompletedProcess(cmd, rc, out, "")


class Starting(unittest.TestCase):
    def setUp(self) -> None:
        self.tmp = tempfile.TemporaryDirectory()
        self.cfg = A.Config(code_dir=self.tmp.name, retry_interval_min=10, retry_window_min=30)
        self.log = A.Log(None)
        self.t = 0.0

    def tearDown(self) -> None:
        self.tmp.cleanup()

    def sleep(self, s: float) -> None:
        self.t += s

    def go(self, fake: FakeRun, route=None, active=lambda r: False):
        route = route or A.Route("code-new", "idee", ["--ttl", "12h"])
        return A.start_session(route, "BRIEF", self.cfg, self.log, runner=fake, active=active,
                               sleep=self.sleep, clock=lambda: self.t)

    def test_started_first_try(self) -> None:
        fake = FakeRun([(0, 'created x\nstarted code-idee with model claude-opus-5-5: open the session "Code: idee" in the Claude app')])
        self.assertEqual(self.go(fake)[:2], (True, "code-idee"))
        self.assertEqual(fake.calls[0][1], "BRIEF")
        self.assertNotIn("--force", fake.calls[0][0])

    def test_ram_refusal_retried_then_new_becomes_existing(self) -> None:
        def second(cmd, **kw):
            (Path(self.tmp.name) / "idee").mkdir(exist_ok=True)
            return subprocess.CompletedProcess(cmd, 1, "", "rc: only 700 MB RAM available (minimum 1024); stop a role or use --force")
        fake = FakeRun([(0, "started code-idee with model m: open the session \"Code: idee\"")])
        calls = []

        def runner(cmd, **kw):
            calls.append(cmd)
            return second(cmd, **kw) if len(calls) == 1 else fake(cmd, **kw)
        ok, role, _ = A.start_session(A.Route("code-new", "idee", ["--ttl", "12h"]), "B", self.cfg, self.log,
                                      runner=runner, active=lambda r: False, sleep=self.sleep, clock=lambda: self.t)
        self.assertTrue(ok)
        self.assertEqual(calls[0][:3], [self.cfg.rc, "code", "--new"])
        self.assertEqual(calls[1][:3], [self.cfg.rc, "code", "idee"])
        self.assertEqual(self.t, 600)

    def test_gives_up_after_window(self) -> None:
        refusal = (1, "rc: only 500 MB RAM available (minimum 1024); stop a role or use --force")
        fake = FakeRun([refusal] * 10)
        ok, _, out = self.go(fake)
        self.assertFalse(ok)
        self.assertEqual(len(fake.calls), 4)  # t = 0, 10, 20, 30 min; the last try falls on the window end
        self.assertIn("RAM", out)

    def test_not_retryable(self) -> None:
        fake = FakeRun([(1, "rc: /x is not trusted: run 'cd ...'")])
        ok, _, _ = self.go(fake)
        self.assertFalse(ok)
        self.assertEqual(len(fake.calls), 1)

    def test_running_role_is_not_touched(self) -> None:
        fake = FakeRun([])
        ok, _, out = self.go(fake, A.Route("code", "repo", ["--fresh"]), active=lambda r: True)
        self.assertFalse(ok)
        self.assertEqual(fake.calls, [])
        self.assertIn("already running", out)

    def test_brief_not_queued_is_a_failure(self) -> None:
        fake = FakeRun([(0, "code-repo is already running (1 sessions)\nbrief not queued: ...")] * 5)
        ok, _, _ = self.go(fake, A.Route("code", "repo", ["--fresh"]))
        self.assertFalse(ok)


class Misc(unittest.TestCase):
    def test_load_env_reads_file_without_executing(self) -> None:
        with tempfile.NamedTemporaryFile("w", delete=False) as f:
            f.write('export NEXTCLOUD_HOST="https://nc.example"\nexport NEXTCLOUD_USERNAME=u\nNEXTCLOUD_PASSWORD=\'p$(x)\'\n')
        import os
        saved = {k: os.environ.pop(k) for k in list(os.environ) if k.startswith("NEXTCLOUD_")}
        try:
            env = A.load_env(Path(f.name))
        finally:
            os.environ.update(saved)
            os.unlink(f.name)
        self.assertEqual(env, {"NEXTCLOUD_HOST": "https://nc.example", "NEXTCLOUD_USERNAME": "u", "NEXTCLOUD_PASSWORD": "p$(x)"})

    def test_put_refuses_other_paths(self) -> None:
        dav = A.CalDAV({"NEXTCLOUD_HOST": "https://nc.example", "NEXTCLOUD_USERNAME": "u", "NEXTCLOUD_PASSWORD": "p"}, "tasks",
                       opener=lambda *a, **k: (_ for _ in ()).throw(AssertionError("no request expected")))
        with self.assertRaises(RuntimeError):
            dav.put("/remote.php/dav/calendars/u/personal/x.ics", "", '"e"')
        with self.assertRaises(RuntimeError):
            A.CalDAV({"NEXTCLOUD_HOST": "http://nc.example", "NEXTCLOUD_USERNAME": "u", "NEXTCLOUD_PASSWORD": "p"}, "tasks")

    def test_mail_only_loopback(self) -> None:
        with self.assertRaises(RuntimeError):
            A.mcp_post("https://evil.example/mcp", {}, None)

    def test_config_rejects_relative_rc(self) -> None:
        with tempfile.NamedTemporaryFile("w", suffix=".toml", delete=False) as f:
            f.write('[sessions]\nrc = "rc"\n')
        try:
            with self.assertRaises(ValueError):
                A.load_config(Path(f.name))
        finally:
            Path(f.name).unlink()


if __name__ == "__main__":
    unittest.main(verbosity=1)
