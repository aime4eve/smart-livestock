#!/usr/bin/env python3
"""NIX-256 T5b: element-level baselines from the drinking prototype."""
import asyncio
from pathlib import Path

from playwright.async_api import async_playwright

PROTO = "http://127.0.0.1:8770/drinking-event-detection-prototype.html"
OUT = Path(__file__).resolve().parent / "drinking" / "prototype-elements"
OUT.mkdir(parents=True, exist_ok=True)

TARGETS = [
    (0, ".card", 1, "card-drinking"),
    (1, ".chart-card", 0, "chart-distribution"),
    (1, ".chart-card", 1, "chart-overlay"),
    (1, ".note-box", None, "note-box"),
    (2, ".card.state-card", 0, "state-no-data"),
    (2, ".card.state-card", 1, "state-building"),
    (2, ".card.state-card", 2, "state-backfill"),
    (3, ".chart-card", None, "fever-layer-card"),
    (4, ".chart-card", 1, "locked-peer-card"),
]


async def main():
    async with async_playwright() as p:
        browser = await p.chromium.launch()
        ctx = await browser.new_context(
            viewport={"width": 390, "height": 844}, device_scale_factor=2, locale="zh-CN"
        )
        page = await ctx.new_page()
        await page.goto(PROTO, wait_until="networkidle")
        await page.wait_for_timeout(400)
        for idx, sel, nth, name in TARGETS:
            loc = page.locator(".phone-shell").nth(idx).locator(sel)
            if nth is not None:
                loc = loc.nth(nth)
            await loc.first.screenshot(path=str(OUT / f"{name}.png"))
            print(f"OK {name}")
        await browser.close()
    print("done")


asyncio.run(main())
