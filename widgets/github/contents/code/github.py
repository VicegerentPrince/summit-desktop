#!/usr/bin/env python3
"""GitHub at a glance for the GitHub card: the build status of the repositories you pushed to last,
your open pull requests with their checks, reviews asked of you, and the notifications that are
about you rather than CI noise.

Uses the GitHub CLI's existing login (gh); stores no token. The last good answer is kept in
~/.cache/summit/github.json, so the card has something to show at once, and offline.

    github.py            fetch (about 6 requests), update the cache, print JSON
    github.py --cached   print the cache only (instant)
    github.py --profiles print the Chrome profiles and the one matching your GitHub email
    github.py --open L   open a summit-github-link: address in Chrome

Links go through that address so that Plasma starts them. Only what Plasma starts may bring a window
forward: a command the card ran itself would load the page in a window left hidden behind the others.
"""
import json
import os
import shutil
import subprocess
import sys
import time
import urllib.parse

CACHE = os.path.join(os.environ.get("XDG_CACHE_HOME") or os.path.expanduser("~/.cache"), "summit", "github.json")
CHROME_DATA = os.path.join(os.environ.get("XDG_CONFIG_HOME") or os.path.expanduser("~/.config"), "google-chrome")
APPLICATIONS = os.path.join(os.environ.get("XDG_DATA_HOME") or os.path.expanduser("~/.local/share"), "applications")
SCHEME = "summit-github-link"
HANDLER = """[Desktop Entry]
Type=Application
Name=GitHub card links
Comment=Opens links from the GitHub card in the Chrome profile chosen in its settings
NoDisplay=true
Exec=python3 -I "{script}" --open %u
MimeType=x-scheme-handler/{scheme};
"""

QUERY = """
query {
  viewer {
    login
    pullRequests(states: OPEN, first: 4, orderBy: {field: UPDATED_AT, direction: DESC}) {
      nodes {
        number title url isDraft reviewDecision updatedAt
        repository { name nameWithOwner }
        commits(last: 1) { nodes { commit { statusCheckRollup { state } } } }
      }
    }
  }
  reviews: search(query: "is:pr is:open archived:false review-requested:@me", type: ISSUE, first: 4) {
    nodes { ... on PullRequest { number title url updatedAt repository { name nameWithOwner } } }
  }
}
"""

REASONS = {"mention": "mentioned you", "team_mention": "mentioned your team", "review_requested": "review requested",
           "assign": "assigned to you", "author": "on your thread", "comment": "new comment", "manual": "you subscribed",
           "invitation": "invitation", "security_alert": "security alert"}
ABOUT_YOU = {"mention", "team_mention", "review_requested", "assign", "author", "comment", "manual", "invitation", "security_alert"}


def gh(*args, timeout=20):
    r = subprocess.run(["gh", *args], capture_output=True, text=True, timeout=timeout,
                       env=dict(os.environ, GH_PROMPT_DISABLED="1", NO_COLOR="1"))
    if r.returncode != 0:
        raise RuntimeError((r.stderr or "gh failed").strip().splitlines()[-1][:200])
    return json.loads(r.stdout or "null")


def ts(iso):
    try:
        return int(time.mktime(time.strptime(iso[:19], "%Y-%m-%dT%H:%M:%S")) - time.timezone)
    except (TypeError, ValueError):
        return 0


def checks_for(repo):
    """The latest run of each workflow on each branch; the repo's row shows the most pressing one."""
    runs = gh("api", f"repos/{repo['nameWithOwner']}/actions/runs?per_page=15").get("workflow_runs", [])
    latest = {}
    for r in runs:
        key = (r.get("name"), r.get("head_branch"))
        if key not in latest:
            latest[key] = r
    if not latest:
        return None
    def state(r):
        if r.get("status") != "completed":
            return "running"
        return {"success": "passed", "skipped": "passed", "neutral": "passed"}.get(r.get("conclusion"), "failed")
    ranked = sorted(latest.values(), key=lambda r: ({"failed": 0, "running": 1, "passed": 2}[state(r)], -ts(r.get("updated_at"))))
    top = ranked[0]
    failing = sum(1 for r in latest.values() if state(r) == "failed")
    return {"repo": repo["name"], "nameWithOwner": repo["nameWithOwner"], "workflow": top.get("name") or "",
            "branch": top.get("head_branch") or "", "state": state(top), "failing": failing,
            "time": ts(top.get("updated_at")), "url": top.get("html_url") or repo["url"]}


def chrome_profiles():
    """Chrome's own list of its profiles, sorted as its profile menu sorts them."""
    if not (shutil.which("google-chrome") or shutil.which("google-chrome-stable")):
        return []
    try:
        with open(os.path.join(CHROME_DATA, "Local State")) as f:
            profiles = json.load(f)["profile"]["info_cache"]
    except (OSError, ValueError, KeyError):
        return []
    found = []
    for folder, p in profiles.items():
        picture = os.path.join(CHROME_DATA, folder, p.get("gaia_picture_file_name") or "Google Profile Picture.png")
        found.append({"folder": folder, "name": p.get("name") or folder, "email": p.get("user_name") or "",
                      "picture": picture if os.path.isfile(picture) else ""})
    return sorted(found, key=lambda p: (p["name"].lower(), p["email"].lower()))


def account_email(cached):
    """The email on the GitHub account, or git's when the account keeps its email private."""
    if cached.get("email"):
        return cached["email"]
    r = subprocess.run(["git", "config", "--global", "user.email"], capture_output=True, text=True)
    return r.stdout.strip()


def matching_profile(email, profiles):
    for p in profiles:
        if email and p["email"].lower() == email.lower():
            return p["folder"]
    return ""


def install_handler():
    """Keeps the entry that lets Plasma start links, written only when it is missing or moved."""
    text = HANDLER.format(script=os.path.abspath(__file__), scheme=SCHEME)
    path = os.path.join(APPLICATIONS, SCHEME + ".desktop")
    try:
        with open(path) as f:
            if f.read() == text:
                return
    except OSError:
        pass
    try:
        os.makedirs(APPLICATIONS, exist_ok=True)
        with open(path, "w") as f:
            f.write(text)
        if shutil.which("kbuildsycoca6"):
            subprocess.run(["kbuildsycoca6"], capture_output=True, timeout=20)
    except (OSError, subprocess.TimeoutExpired):
        pass


def open_link(link):
    q = urllib.parse.parse_qs(urllib.parse.urlsplit(link).query)
    url = q.get("url", [""])[0]
    if not url.startswith("https://"):
        sys.exit(1)
    chrome = shutil.which("google-chrome") or shutil.which("google-chrome-stable")
    args = [chrome]
    folder = q.get("profile", [""])[0]
    if any(p["folder"] == folder for p in chrome_profiles()):   # Chrome would create a missing one
        args.append("--profile-directory=" + folder)
    if q.get("window") == ["new"]:
        args.append("--new-window")
    os.execv(chrome, args + [url])


def fetch():
    data = gh("api", "graphql", "-f", f"query={QUERY}")["data"]
    viewer = data["viewer"]
    prs = []
    for n in viewer["pullRequests"]["nodes"]:
        rollup = ((n.get("commits") or {}).get("nodes") or [{}])[0].get("commit", {}).get("statusCheckRollup") or {}
        prs.append({"number": n["number"], "title": n["title"], "url": n["url"], "repo": n["repository"]["name"],
                    "draft": n["isDraft"], "review": n.get("reviewDecision") or "", "checks": (rollup.get("state") or "").lower(),
                    "time": ts(n.get("updatedAt")), "kind": "mine"})
    for n in data["reviews"]["nodes"]:
        if n:
            prs.append({"number": n["number"], "title": n["title"], "url": n["url"], "repo": n["repository"]["name"],
                        "draft": False, "review": "", "checks": "", "time": ts(n.get("updatedAt")), "kind": "review"})
    prs.sort(key=lambda p: (p["kind"] != "review", -p["time"]))
    builds = []
    # REST, not GraphQL: GraphQL's repository list leaves out organisation repositories you are a
    # collaborator on, which is where team projects live.
    repos = gh("api", "user/repos?sort=pushed&per_page=8&affiliation=owner,collaborator,organization_member")
    for r in repos:
        repo = {"name": r["name"], "nameWithOwner": r["full_name"], "url": r["html_url"]}
        if len(builds) == 3:
            break
        try:
            c = checks_for(repo)
        except (RuntimeError, subprocess.SubprocessError, ValueError):
            c = None
        if c:
            builds.append(c)
    notes = gh("api", "notifications?per_page=50")
    about = [n for n in notes if n.get("reason") in ABOUT_YOU]
    for_you = []
    for n in about[:3]:
        subject = n.get("subject") or {}
        api = subject.get("url") or ""
        url = (api.replace("https://api.github.com/repos/", "https://github.com/", 1).replace("/pulls/", "/pull/")
               if api else n.get("repository", {}).get("html_url", "https://github.com/notifications"))
        for_you.append({"title": subject.get("title") or "", "repo": n.get("repository", {}).get("name", ""),
                        "reason": REASONS.get(n.get("reason"), n.get("reason", "")), "url": url,
                        "time": ts(n.get("updated_at"))})
    return {"login": viewer["login"], "email": gh("api", "user").get("email") or "", "builds": builds, "prs": prs[:4], "for_you": for_you,
            "notifications": {"about_you": len(about), "total": len(notes)}, "updated": int(time.time())}


def main():
    if "--open" in sys.argv:
        open_link(sys.argv[sys.argv.index("--open") + 1])
        return
    cached = {}
    try:
        with open(CACHE) as f:
            cached = json.load(f)
    except (OSError, ValueError):
        pass
    profiles = chrome_profiles()
    email = account_email(cached)
    if "--profiles" in sys.argv:
        print(json.dumps({"email": email, "match": matching_profile(email, profiles), "profiles": profiles}))
        return
    if "--cached" in sys.argv:
        install_handler()
        print(json.dumps(dict(cached, chrome_profile=matching_profile(email, profiles))))
        return
    try:
        out = fetch()
        os.makedirs(os.path.dirname(CACHE), exist_ok=True)
        tmp = CACHE + ".tmp"
        with open(tmp, "w") as f:
            json.dump(out, f)
        os.replace(tmp, CACHE)
    except FileNotFoundError:
        out = dict(cached, error="GitHub CLI (gh) is not installed")
    except Exception as e:  # offline, logged out, rate limited: keep showing the last good answer
        text = str(e).lower()
        if "auth" in text or "token" in text or "login" in text:
            why = "Sign in with gh auth login"
        elif "rate limit" in text:
            why = "GitHub rate limit, trying again soon"
        else:
            why = "GitHub is not reachable"
        out = dict(cached, error=why)
    print(json.dumps(dict(out, chrome_profile=matching_profile(account_email(out), profiles))))


if __name__ == "__main__":
    main()
