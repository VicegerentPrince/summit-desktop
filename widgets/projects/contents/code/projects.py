#!/usr/bin/env python3
"""Recent git projects for the Projects card: branch, uncommitted changes, unpushed commits.

Finds repositories (folders holding a .git directory) up to two levels under the roots, orders them
by when you last worked in them (the newest of .git/index, .git/HEAD and .git/logs/HEAD) and prints
the newest few as JSON, with your commits per day over the last week.

git runs with --no-optional-locks, so a check never rewrites a repository's index, and so never makes
a project look recently used by itself. Read-only, no network.

    projects.py [COUNT] [ROOT...]        defaults: 5, ~/Documents/Projects
"""
import json
import os
import subprocess
import sys
import time


def find_repos(roots):
    for root in roots:
        for level in (0, 1):
            base_dirs = [root] if level == 0 else [e.path for e in scandirs(root)]
            for base in base_dirs:
                for e in scandirs(base):
                    if os.path.isdir(os.path.join(e.path, ".git")):
                        yield e.path


def scandirs(path):
    try:
        with os.scandir(path) as it:
            return [e for e in it if not e.name.startswith(".") and e.is_dir(follow_symlinks=False)]
    except OSError:
        return []


def last_active(repo):
    """Newest sign of work, linked worktrees included (agents often work in those)."""
    git_dir = os.path.join(repo, ".git")
    dirs = [git_dir] + [e.path for e in scandirs(os.path.join(git_dir, "worktrees"))]
    best = 0.0
    for d in dirs:
        for rel in ("index", "HEAD", "logs/HEAD"):
            try:
                best = max(best, os.stat(os.path.join(d, rel)).st_mtime)
            except OSError:
                pass
    return best


def git(repo, *args):
    r = subprocess.run(["git", "--no-optional-locks", "-C", repo, *args],
                       capture_output=True, text=True, timeout=4,
                       env=dict(os.environ, GIT_TERMINAL_PROMPT="0", LC_ALL="C"))
    return r.stdout if r.returncode == 0 else None


def describe(repo):
    p = {"name": os.path.basename(repo), "path": repo, "branch": "", "changed": 0, "untracked": 0,
         "ahead": 0, "behind": 0, "upstream": False, "remote": False, "commit_time": 0, "subject": ""}
    out = git(repo, "status", "--porcelain=v2", "--branch", "--untracked-files=normal")
    if out is None:
        p["error"] = True
        return p
    for line in out.splitlines():
        if line.startswith("# branch.head "):
            head = line[14:]
            p["branch"] = "" if head == "(detached)" else head
        elif line.startswith("# branch.upstream "):
            p["upstream"] = True
        elif line.startswith("# branch.ab "):
            a, b = line[12:].split()
            p["ahead"], p["behind"] = int(a), -int(b)
        elif line.startswith("? "):
            p["untracked"] += 1
        elif line and not line.startswith("#"):
            p["changed"] += 1
    if not p["branch"]:
        p["branch"] = (git(repo, "rev-parse", "--short", "HEAD") or "").strip() or "detached"
    p["remote"] = bool((git(repo, "remote") or "").strip())
    log = git(repo, "log", "-1", "--format=%ct%x09%s")
    if log and "\t" in log:
        t, subject = log.rstrip("\n").split("\t", 1)
        p["commit_time"], p["subject"] = int(t), subject
    if p["remote"] and not p["upstream"] and p["commit_time"]:
        # a branch that was never pushed: count its commits that no remote branch has
        n = git(repo, "rev-list", "--count", "HEAD", "--not", "--remotes")
        p["ahead"] = int(n.strip()) if n and n.strip().isdigit() else 0
    return p


def week(repos, now):
    """Your commits per day over the last seven days (today last), per project, all branches."""
    t = time.localtime(now)
    day0 = int(time.mktime((t.tm_year, t.tm_mon, t.tm_mday, 0, 0, 0, 0, 0, -1))) - 6 * 86400
    rows = []
    for repo in repos:
        email = (git(repo, "config", "user.email") or "").strip()
        if not email:
            continue
        out = git(repo, "log", "--all", f"--since={day0}", f"--author={email}", "--format=%ct") or ""
        counts = [0] * 7
        for line in out.split():
            i = (int(line) - day0) // 86400
            if 0 <= i < 7:
                counts[i] += 1
        if sum(counts):
            rows.append({"name": os.path.basename(repo), "counts": counts})
    rows.sort(key=lambda r: -sum(r["counts"]))
    return {"start": day0, "projects": rows, "total": sum(sum(r["counts"]) for r in rows)}


def main():
    count = int(sys.argv[1]) if len(sys.argv) > 1 and sys.argv[1].isdigit() else 5
    roots = [os.path.expanduser(r) for r in sys.argv[2:]] or [os.path.expanduser("~/Documents/Projects")]
    now = time.time()
    ranked = sorted(set(find_repos(roots)), key=last_active, reverse=True)
    # Look a little further than the rows shown: commits nobody has pushed are the one thing that
    # must never fall off the card, so such a project takes the place of the oldest clean one.
    described = []
    for repo in ranked[:count + 4]:
        try:
            p = describe(repo)
        except (subprocess.SubprocessError, OSError, ValueError):
            p = {"name": os.path.basename(repo), "path": repo, "error": True}
        p["active_time"] = int(last_active(repo))
        described.append(p)
    projects = described[:count]
    for p in described[count:]:
        if p.get("ahead"):
            spare = [q for q in projects if not q.get("ahead")]
            if spare:
                projects.remove(spare[-1])
                projects.append(p)
    projects.sort(key=lambda p: -p["active_time"])
    home = os.path.expanduser("~")
    recent = [r for r in ranked[:12] if last_active(r) >= now - 8 * 86400]
    try:
        activity = week(recent, now)
    except (subprocess.SubprocessError, OSError, ValueError):
        activity = {"start": 0, "projects": [], "total": 0}
    print(json.dumps({"generated": int(now),
                      "roots": [r.replace(home, "~", 1) for r in roots],
                      "projects": projects, "week": activity}))


if __name__ == "__main__":
    main()
