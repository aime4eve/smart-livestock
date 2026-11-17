import json, os, re, sys, urllib.request

api = os.environ["CI_API_V4_URL"]; pid = os.environ["CI_PROJECT_ID"]
iid = os.environ["CI_MERGE_REQUEST_IID"]; tok = os.environ["GATE_TOKEN"]

def get(path):
    req = urllib.request.Request(f"{api}/projects/{pid}{path}", headers={"PRIVATE-TOKEN": tok})
    return json.load(urllib.request.urlopen(req))

fails = []
# gate 1: conventional title
title = os.environ.get("CI_MERGE_REQUEST_TITLE", "")
if not re.match(r"^(feat|fix|docs|style|refactor|perf|test|chore|build|ci|revert)(\(.+\))?!?: .+", title):
    fails.append(f"MR title not conventional: {title!r}")

# gate 2: maintainer approval via /approve quick action.
# GitLab consumes "/approve" and emits a system note "approved this merge request";
# "/unapprove" emits "unapproved this merge request". Per approver, latest state wins.
mr = get(f"/merge_requests/{iid}")
author = mr["author"]["id"]
notes = sorted(get(f"/merge_requests/{iid}/notes?per_page=100"), key=lambda n: n["id"])
state = {}  # uid -> True(approved)/False(unapproved)
for n in notes:
    body = n.get("body") or ""
    if "approved this merge request" in body:
        state[n["author"]["id"]] = True
    elif "unapproved this merge request" in body:
        state[n["author"]["id"]] = False
    elif not n.get("system") and "/approve" in body:
        state[n["author"]["id"]] = True  # fallback if quick actions disabled
ok = False
for uid, approved in state.items():
    if not approved or uid == author:
        continue
    if get(f"/members/all/{uid}").get("access_level", 0) >= 40:
        ok = True; break
if not ok:
    fails.append("no maintainer approval (non-author /approve)")

if fails:
    print("MR GATES FAILED:")
    for f in fails: print(" -", f)
    sys.exit(1)
print("MR gates passed")
