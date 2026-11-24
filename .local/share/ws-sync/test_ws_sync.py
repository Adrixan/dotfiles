#!/usr/bin/env python3
"""Offline tests for ws-sync's decision logic (no SSH, no changes): python3 -I ~/.local/share/ws-sync/test_ws_sync.py"""
from __future__ import annotations

import argparse
import importlib.machinery
import importlib.util
import json
import os
import sys
import tempfile
import time
import unittest
from pathlib import Path

# Temporary files under ~/.cache, never /tmp (workstation rule).
(Path.home() / ".cache").mkdir(exist_ok=True)
tempfile.tempdir = str(Path.home() / ".cache")

SCRIPT = Path(os.environ.get("WS_SYNC_SCRIPT", Path.home() / ".local/bin/ws-sync"))
_loader = importlib.machinery.SourceFileLoader("wss", str(SCRIPT))
_spec = importlib.util.spec_from_loader("wss", _loader)
wss = importlib.util.module_from_spec(_spec)
sys.modules["wss"] = wss
_loader.exec_module(wss)

CFG = {
    "hosts": {"alpha": {"ssh": "alpha", "ansible_roles": ["ai_workstation"]}, "beta": {"ssh": "b"}},
    "code": {"push_remotes": ["git@github.com:me/*"], "push_in": ["sync", "handoff"],
             "push_default_branch_in": ["sync", "handoff"], "push_untracked_in": ["handoff"],
             "read_only": ["archived"]},
    "packages": {"ignore": ["kernel-*"], "host_specific": {"alpha": ["sdbootutil"]}},
    "timers": {"ignore": ["user:rc-ttl-*"], "only_on": {"alpha": ["user:backup.timer"]}},
}


def host_data(name: str, **over) -> dict:
    d = {
        "host": name, "time": int(time.time()),
        "packages": {"installed": ["bash", "git"], "auto": [], "repos": []},
        "flatpak": {}, "uv": {}, "docker": {"available": False}, "timers": [],
        "code": {"repos": {}, "exclude": []},
        "yadm": {"present": True, "head": "a", "origin": "a", "ahead": 0, "behind": 0, "dirty": [], "cipher": "gpg",
                 "secrets": {"checked": True, "members": 1, "missing": [], "newer_local": [], "older_local": []}},
        "rc": {"confs": {}, "running": [], "lease": "", "holds_lease": False},
        "mcp": {"up": True, "servers": {}}, "syncthing": {"up": True, "folders": {}, "connected": ["m11x"]},
        "tools": {}, "ansible": {"present": False},
    }
    d.update(over)
    return d


def repo(origin: str, branches: dict, **over) -> dict:
    r = {"origin": origin, "current": "main", "default": "main", "dirty": 0, "dirty_files": [], "stash": 0,
         "branches": branches}
    r.update(over)
    return r


def br(sha: str, up: str = "origin/main", ahead: int = 0, behind: int = 0, **over) -> dict:
    b = {"sha": sha, "up": up, "ahead": ahead, "behind": behind, "gone": False}
    b.update(over)
    return b


class Base(unittest.TestCase):
    def coord(self, mode: str = "sync", auto: bool = False, a: dict | None = None, b: dict | None = None,
              baseline: dict | None = None) -> "wss.Coordinator":
        args = argparse.Namespace(mode=mode, peer="beta", only=None, skip=None, verbose=True, dry_run=True,
                                  auto=auto, to=None, force=False)
        orig = wss.short_host
        wss.short_host = lambda: "alpha"
        try:
            c = wss.Coordinator(args, json.loads(json.dumps(CFG)))
        finally:
            wss.short_host = orig
        if hasattr(self, "tmp"):
            self.tmp.cleanup()
        self.tmp = tempfile.TemporaryDirectory()
        c.state_dir = Path(self.tmp.name)
        if baseline is not None:
            (c.state_dir / "baseline.json").write_text(json.dumps(baseline))
        c.me.data = a or host_data("alpha")
        c.peer.data = b or host_data("beta")
        c.analyse()
        return c

    def tearDown(self) -> None:
        if hasattr(self, "tmp"):
            self.tmp.cleanup()

    def items(self, c, section: str) -> list:
        return [i for i in c.items if i.section == section]


class CodeTests(Base):
    def test_branch_already_on_merge_request_branch_is_not_pushed(self):
        a = host_data("alpha", code={"repos": {"r": repo("git@github.com:me/r.git", {"main": br("s1", ahead=72,
                                     on_remote=["origin/merge/x"])})}, "exclude": []})
        b = host_data("beta", code={"repos": {"r": repo("git@github.com:me/r.git", {"main": br("s1", ahead=72,
                                    on_remote=["origin/merge/x"])})}, "exclude": []})
        it = self.items(self.coord(a=a, b=b), "code")
        self.assertTrue(it and all(i.level == "info" and not i.fix for i in it))

    def test_merged_diverged_branch_is_dropped_unless_checked_out(self):
        branches = {"main": br("s0"), "feat": br("s5", up="origin/feat", ahead=3, behind=2, merged=True)}
        a = host_data("alpha", code={"repos": {"r": repo("git@github.com:me/r.git", branches)}, "exclude": []})
        b = host_data("beta", code={"repos": {"r": repo("git@github.com:me/r.git", {"main": br("s0")})},
                                    "exclude": []})
        self.assertTrue(any(i.fix == "drop the merged local copy on alpha" for i in self.items(self.coord(a=a, b=b), "code")))
        a["code"]["repos"]["r"]["current"] = "feat"
        it = self.items(self.coord(a=a, b=b), "code")
        self.assertTrue(any("resolve by hand" in i.text and not i.fix for i in it))

    def test_unmerged_diverged_branch_stops_for_a_person(self):
        branches = {"main": br("s0"), "feat": br("s5", up="origin/feat", ahead=1, behind=1, merged=False)}
        a = host_data("alpha", code={"repos": {"r": repo("git@github.com:me/r.git", branches)}, "exclude": []})
        b = host_data("beta", code={"repos": {"r": repo("git@github.com:me/r.git", {"main": br("s0")})},
                                    "exclude": []})
        it = self.items(self.coord(a=a, b=b), "code")
        self.assertTrue(any("never force-pushes" in i.text and i.level == "warn" and not i.fix for i in it))

    def test_read_only_repo_dirty_is_a_note(self):
        a = host_data("alpha", code={"repos": {"archived": repo("git@github.com:me/a.git", {"main": br("s0")},
                                                                dirty=1, dirty_files=[".agents/x.md"])}, "exclude": []})
        b = host_data("beta", code={"repos": {"archived": repo("git@github.com:me/a.git", {"main": br("s0")})},
                                    "exclude": []})
        it = self.items(self.coord(a=a, b=b), "code")
        self.assertTrue(it and all(i.level == "info" for i in it))

    def test_foreign_remote_is_never_pushed(self):
        a = host_data("alpha", code={"repos": {"client": repo("git@gitlab.com:client/x.git",
                                                              {"main": br("s1", ahead=3)})}, "exclude": []})
        b = host_data("beta", code={"repos": {"client": repo("git@gitlab.com:client/x.git",
                                                             {"main": br("s0")})}, "exclude": []})
        it = self.items(self.coord(a=a, b=b), "code")
        self.assertTrue(any("not on code.push_remotes" in i.text and not i.fix and i.level == "warn" for i in it))

    def test_own_remote_ahead_is_pushed_in_sync_not_auto(self):
        a = host_data("alpha", code={"repos": {"r": repo("git@github.com:me/r.git", {"main": br("s1", ahead=1)})},
                                     "exclude": []})
        b = host_data("beta", code={"repos": {"r": repo("git@github.com:me/r.git", {"main": br("s0")})},
                                    "exclude": []})
        self.assertTrue(any(i.fix == "push from alpha" for i in self.items(self.coord(a=a, b=b), "code")))
        self.assertFalse(any(i.fix for i in self.items(self.coord(auto=True, a=a, b=b), "code")))

    def test_untracked_branch_only_in_handoff(self):
        branches = {"main": br("s0"), "wip": br("s9", up="", unpushed=True)}
        a = host_data("alpha", code={"repos": {"r": repo("git@github.com:me/r.git", branches)}, "exclude": []})
        b = host_data("beta", code={"repos": {"r": repo("git@github.com:me/r.git", {"main": br("s0")})},
                                    "exclude": []})
        self.assertFalse(any(i.fix for i in self.items(self.coord("sync", a=a, b=b), "code")))
        self.assertTrue(any(i.fix.startswith("push -u") for i in self.items(self.coord("handoff", a=a, b=b), "code")))

    def test_missing_repo_cloned_unless_excluded(self):
        a = host_data("alpha", code={"repos": {"r": repo("git@github.com:me/r.git", {"main": br("s0")})},
                                     "exclude": []})
        self.assertTrue(any(i.fix == "clone on beta" for i in self.items(self.coord(a=a), "code")))
        b = host_data("beta", code={"repos": {}, "exclude": ["r"]})
        self.assertEqual(self.items(self.coord(a=a, b=b), "code"), [])

    def test_dirty_checkout_blocks_fast_forward_fix(self):
        a = host_data("alpha", code={"repos": {"r": repo("git@github.com:me/r.git", {"main": br("s1")})},
                                     "exclude": []})
        b = host_data("beta", code={"repos": {"r": repo("git@github.com:me/r.git", {"main": br("s0")}, dirty=2,
                                                        dirty_files=["x"])}, "exclude": []})
        it = self.items(self.coord(a=a, b=b), "code")
        self.assertTrue(any("block the fast-forward" in i.text and not i.fix for i in it))


class SecretsTests(Base):
    def test_one_machine_with_edits_gets_reencrypt_fix(self):
        a = host_data("alpha")
        a["yadm"]["secrets"]["newer_local"] = [".config/ai/env.local"]
        it = self.items(self.coord(a=a), "secrets")
        self.assertEqual([i.fix for i in it], ["yadm-reencrypt --changed on alpha"])

    def test_edits_on_both_machines_warn_without_fix(self):
        a, b = host_data("alpha"), host_data("beta")
        a["yadm"]["secrets"]["newer_local"] = [".config/ai/env.local"]
        b["yadm"]["secrets"]["newer_local"] = [".config/ai/env"]
        it = self.items(self.coord(a=a, b=b), "secrets")
        self.assertTrue(len(it) == 2 and all(i.level == "warn" and not i.fix for i in it))

    def test_reencrypt_plan_pulls_without_decrypt_first(self):
        a = host_data("alpha")
        a["yadm"].update(behind=1)
        a["yadm"]["secrets"].update(newer_local=[".config/ai/env.local"], older_local=[".config/ai/env"])
        c = self.coord(a=a)
        import io, contextlib
        buf = io.StringIO()
        with contextlib.redirect_stdout(buf):
            c.step_yadm()
        lines = [x.strip() for x in buf.getvalue().splitlines()]
        self.assertTrue(lines[0].startswith("would run [alpha] yadm-sync-all -u --no-decrypt alpha"), lines)
        self.assertIn("take .config/ai/env from the archive", lines[1])
        self.assertIn("yadm-reencrypt --changed", lines[2])
        self.assertTrue(lines[3].startswith("would run [alpha] yadm-sync-all -u b"), lines)   # beta pulls, decrypts


class YadmFailureTests(Base):
    def test_collision_is_reported_without_fix(self):
        a = host_data("alpha")
        a["yadm"].update(behind=3, collide=[".zshenv"])
        it = self.items(self.coord(a=a), "yadm")
        texts = [i.text for i in it]
        self.assertIn("alpha: 3 commits behind origin", texts)
        hit = [i for i in it if ".zshenv" in i.text]
        self.assertEqual(len(hit), 1)
        self.assertEqual((hit[0].level, hit[0].fix), ("drift", ""))
        self.assertIn("yadm-sync-all -n alpha", hit[0].text)

    def test_fail_reason_takes_the_host_fail_line_with_its_continuation(self):
        out = ("== xps\n  [xps13] merge --ff-only origin/master\n"
               "  [xps13] FAIL: fast-forward failed: error: The following untracked working tree files would be "
               "overwritten by merge:\n\t.zshenv\nPlease move or remove them before you merge.\n\n"
               "Summary (sync):\n  xps        FAIL\n")
        r = wss.fail_reason(out)
        self.assertTrue(r.startswith(": [xps13] FAIL: fast-forward failed"), r)
        self.assertTrue(r.endswith("overwritten by merge: .zshenv"), r)
        self.assertNotIn("Summary", r)

    def test_fail_reason_falls_back_to_last_line_and_empty(self):
        self.assertEqual(wss.fail_reason("one\ntwo\n\n"), ": two")
        self.assertEqual(wss.fail_reason(""), "")

    def test_failed_act_keeps_the_reason(self):
        c = self.coord()
        c.dry = False
        c.me.local = True
        import io, contextlib
        with contextlib.redirect_stdout(io.StringIO()):
            ok = c.act(c.me, "demo", "echo '  [alpha] FAIL: no key'; exit 1")
        self.assertFalse(ok)
        self.assertEqual(c.failures, ["[alpha] demo: exit 1: [alpha] FAIL: no key"])


class UvTests(Base):
    def test_pinned_older_tool_reinstalled_unpinned(self):
        a = host_data("alpha", uv={"p": {"requirements": [{"name": "p", "specifier": "==1.0"}], "version": "1.0"}})
        b = host_data("beta", uv={"p": {"requirements": [{"name": "p"}], "version": "1.2"}})
        it = self.items(self.coord(a=a, b=b), "uv")
        self.assertEqual([i.fix for i in it], ["reinstall unpinned on alpha"])

    def test_git_source_reported_not_installed(self):
        a = host_data("alpha", uv={"g": {"requirements": [{"name": "g", "git": "https://x"}], "version": "1"}})
        it = self.items(self.coord(a=a), "uv")
        self.assertTrue(it and not it[0].fix and it[0].level == "warn")

    def test_missing_registry_tool_installed(self):
        a = host_data("alpha", uv={"t": {"requirements": [{"name": "t", "extras": ["cli"], "specifier": ">=2"}],
                                         "version": "2.1"}})
        c = self.coord(a=a)
        self.assertEqual(c.uv_spec(c.me.data["uv"]["t"]), ("t[cli]>=2", ""))
        self.assertEqual(self.items(c, "uv")[0].fix, "uv tool install on beta")


class PackageTests(Base):
    def test_no_baseline_trusts_maintained_autoinstalled_only(self):
        a = host_data("alpha", packages={"installed": ["bash", "git", "lib1", "lib2", "lib3", "lib4", "texlive", "steam",
                                                       "kernel-x", "sdbootutil"],
                                         "auto": ["bash", "git", "lib1", "lib2", "lib3", "lib4"], "repos": []})
        b = host_data("beta", packages={"installed": ["bash", "git", "extra"], "auto": [], "repos": []})
        it = self.items(self.coord(a=a, b=b), "packages")
        fixes = sorted(i.text.split(":")[0] for i in it if i.fix)
        self.assertEqual(fixes, ["steam", "texlive"])            # kernel-* ignored
        self.assertTrue(any("beta: no baseline" in i.text for i in it))

    def test_baseline_proposes_new_and_notes_removed(self):
        a = host_data("alpha", packages={"installed": ["bash", "new"], "auto": [], "repos": []})
        b = host_data("beta", packages={"installed": ["bash", "gone"], "auto": [], "repos": []})
        base = {"packages": {"alpha": ["bash", "gone"], "beta": ["bash", "gone"]}}
        it = self.items(self.coord(a=a, b=b, baseline=base), "packages")
        self.assertTrue(any(i.text.startswith("new:") and i.fix == "zypper install on beta" for i in it))
        self.assertTrue(any(i.text.startswith("gone:") and "removed on alpha" in i.text and not i.fix for i in it))


    def test_maintained_autoinstalled_beats_an_old_baseline(self):
        a = host_data("alpha", packages={"installed": ["l1", "l2", "l3", "steam"], "auto": ["l1", "l2", "l3"],
                                         "repos": []})
        base = {"packages": {"alpha": ["l1", "l2", "l3", "steam"], "beta": []}}
        it = self.items(self.coord(a=a, baseline=base), "packages")
        self.assertTrue(any(i.text.startswith("steam:") and i.fix for i in it))


class AnsibleTests(Base):
    def ans(self, **over) -> dict:
        d = {"present": True, "head": "h2", "head_time": 0, "branch": "master", "hosts_sha": "x", "hosts_mtime": 0,
             "stamp": {"ok": True, "head": "h1", "hosts_sha": "x", "roles": ["ai_workstation"]}, "topgrade": {},
             "topgrade_timer": False, "changed_since_stamp": []}
        d.update(over)
        return d

    def test_docs_only_change_needs_no_role_run(self):
        c = self.coord(a=host_data("alpha", ansible=self.ans()))
        self.assertEqual(c.ansible_due(c.me), "")

    def test_role_file_change_or_hosts_change_is_due(self):
        c = self.coord(a=host_data("alpha", ansible=self.ans(changed_since_stamp=["roles/x/tasks/main.yml"])))
        self.assertTrue(c.ansible_due(c.me))
        c = self.coord(a=host_data("alpha", ansible=self.ans(hosts_sha="y")))
        self.assertTrue(c.ansible_due(c.me))


class LeaseAndTimerTests(Base):
    def test_roles_on_both_machines_warn(self):
        a = host_data("alpha")
        b = host_data("beta")
        a["rc"].update(running=[{"role": "greeter", "sessions": 1}], holds_lease=True)
        b["rc"].update(running=[{"role": "code-x", "sessions": 1}])
        it = self.items(self.coord(a=a, b=b), "lease")
        self.assertEqual(len(it), 2)

    def test_timer_exceptions(self):
        a = host_data("alpha", timers=["user:backup.timer", "user:rc-ttl-foo.timer", "user:shared.timer"])
        it = self.items(self.coord(a=a), "timers")
        self.assertEqual([i.text.split(":")[0] + ":" + i.text.split(":")[1] for i in it], ["user:shared.timer"])


class HostSideTests(unittest.TestCase):
    def test_barrier_recent_window_counts_from_newest_file(self):
        with tempfile.TemporaryDirectory() as d:
            p = Path(d)
            old, new, older = p / "old.jsonl", p / "new.jsonl", p / "older.jsonl"
            for f in (old, new, older):
                f.write_text(f.name)
            now = time.time()
            os.utime(new, (now - 86400, now - 86400))          # newest: a day old
            os.utime(old, (now - 86400 - 600, now - 86400 - 600))  # 10 min before it: inside a 60 min window
            os.utime(older, (now - 3 * 86400,) * 2)             # far outside
            import io
            import contextlib
            buf = io.StringIO()
            with contextlib.redirect_stdout(buf):
                wss.h_barrier_hash(argparse.Namespace(window_min=60, paths=[f"recent:{d}"], files=None))
            got = {Path(k).name for k in json.loads(buf.getvalue())}
            self.assertEqual(got, {"new.jsonl", "old.jsonl"})

    def test_merged_into_and_on_other_remote_with_real_git(self):
        import subprocess
        with tempfile.TemporaryDirectory() as d:
            env = {**os.environ, "GIT_AUTHOR_NAME": "t", "GIT_AUTHOR_EMAIL": "t@t", "GIT_COMMITTER_NAME": "t",
                   "GIT_COMMITTER_EMAIL": "t@t", "GIT_CONFIG_GLOBAL": "/dev/null"}
            def g(*a, cwd=d + "/w"):
                return subprocess.run(["git", *a], cwd=cwd, env=env, capture_output=True, text=True, check=True).stdout
            subprocess.run(["git", "init", "-q", "--bare", "-b", "main", d + "/r.git"], check=True, env=env)
            subprocess.run(["git", "clone", "-q", d + "/r.git", d + "/w"], check=True, env=env, capture_output=True)
            w = Path(d) / "w"
            def commit(name):
                (w / name).write_text(name)
                g("add", name)
                g("commit", "-q", "-m", name)
            g("checkout", "-q", "-b", "main")
            commit("base")
            g("push", "-q", "-u", "origin", "main")
            g("checkout", "-q", "-b", "feat")
            commit("f1")
            g("push", "-q", "-u", "origin", "feat")
            g("checkout", "-q", "main")
            commit("m1")
            g("push", "-q", "origin", "main")
            g("checkout", "-q", "feat")
            g("rebase", "-q", "main")                      # local feat now diverges from origin/feat
            g("checkout", "-q", "main")
            g("merge", "-q", "--ff-only", "feat")
            g("push", "-q", "origin", "main")
            g("fetch", "-q")
            self.assertTrue(wss.merged_into(w, "feat", "origin/feat", "origin/main"))
            g("checkout", "-q", "feat")
            commit("f2")                                   # a new commit only on the local copy
            self.assertFalse(wss.merged_into(w, "feat", "origin/feat", "origin/main"))
            g("push", "-q", "origin", "feat:merge/f2")     # the same commit on a merge-request branch
            g("fetch", "-q")
            sha = g("rev-parse", "feat").strip()
            self.assertEqual(wss.on_other_remote(w, sha, "origin/feat"), ["origin/merge/f2"])

    def test_yadm_collisions_with_real_git(self):
        import subprocess
        with tempfile.TemporaryDirectory() as d:
            env = {**os.environ, "GIT_AUTHOR_NAME": "t", "GIT_AUTHOR_EMAIL": "t@t", "GIT_COMMITTER_NAME": "t",
                   "GIT_COMMITTER_EMAIL": "t@t", "GIT_CONFIG_GLOBAL": "/dev/null"}
            home, bare = Path(d) / "home", Path(d) / "repo.git"
            home.mkdir()
            def g(*a):
                return subprocess.run(["git", f"--git-dir={bare}", f"--work-tree={home}", *a], env=env,
                                      capture_output=True, text=True, check=True).stdout
            subprocess.run(["git", "init", "-q", "--bare", "-b", "master", str(bare)], check=True, env=env)
            (home / "base").write_text("base")
            g("add", "base"); g("commit", "-q", "-m", "base")
            base = g("rev-parse", "HEAD").strip()
            for name, text in ((".zshenv", "new"), ("same", "same"), ("absent", "x")):
                (home / name).write_text(text)
            g("add", ".zshenv", "same", "absent"); g("commit", "-q", "-m", "add")
            g("update-ref", "refs/remotes/origin/master", "HEAD")
            g("reset", "-q", "--soft", base); g("rm", "-q", "--cached", ".zshenv", "same", "absent")
            (home / ".zshenv").write_text(". \"$HOME/.cargo/env\"\n")   # untracked, other content
            (home / "absent").unlink()                                  # not on disk: no collision
            orig = (wss.YADM_REPO, wss.HOME)
            wss.YADM_REPO, wss.HOME = bare, home
            try:
                self.assertEqual(wss.yadm_collisions(), [".zshenv"])
            finally:
                wss.YADM_REPO, wss.HOME = orig

    def test_stamp_lines(self):
        with tempfile.TemporaryDirectory() as d:
            orig = wss.LOCAL_STATE
            wss.LOCAL_STATE = Path(d)
            try:
                wss.write_stamp("sync", ["sync", "3-left", "beta"])
                wss.write_stamp("check", ["0", "beta"])
                lines = (Path(d) / "last").read_text().splitlines()
            finally:
                wss.LOCAL_STATE = orig
            self.assertEqual([x.split()[0] for x in lines], ["sync", "check"])
            self.assertEqual(lines[0].split()[2:], ["sync", "3-left", "beta"])


if __name__ == "__main__":
    unittest.main(verbosity=1)
