#!/usr/bin/env python3
"""NIX-256 Task 0: capture prototype baselines at 390x844 logical, DPR 2."""
from pathlib import Path
from playwright.sync_api import sync_playwright

BASE = Path(__file__).resolve().parent
JOBS = [
    (
        "http://127.0.0.1:8770/drinking-event-detection-prototype.html",
        ".phone-shell",
        BASE / "drinking" / "prototype",
        6,
    ),
    (
        "http://127.0.0.1:8770/physiology-events-p1-prototype.html",
        ".phone",
        BASE / "physiology" / "prototype",
        2,
    ),
]

with sync_playwright() as p:
    browser = p.chromium.launch()
    ctx = browser.new_context(
        viewport={"width": 390, "height": 844}, device_scale_factor=2
    )
    page = ctx.new_page()
    for url, selector, outdir, expected in JOBS:
        outdir.mkdir(parents=True, exist_ok=True)
        page.goto(url, wait_until="networkidle")
        page.wait_for_timeout(400)
        shells = page.locator(selector)
        count = shells.count()
        assert count == expected, f"{url}: expected {expected} shells, got {count}"
        for i in range(count):
            path = outdir / f"screen-{i + 1:02d}.png"
            shells.nth(i).scroll_into_view_if_needed()
            shells.nth(i).screenshot(path=str(path))
            print(f"OK {path}")
    browser.close()
print("done")
