#!/usr/bin/env python3
"""NIX-256 T1b: element-level prototype baselines for pairwise comparison."""
import asyncio
from pathlib import Path

from playwright.async_api import async_playwright

PROTO = "http://127.0.0.1:8770/physiology-events-p1-prototype.html"
OUT = Path(__file__).resolve().parent / "physiology" / "prototype-elements"
OUT.mkdir(parents=True, exist_ok=True)

# (css selector, output name, viewport width for element shots)
TARGETS = [
    (".phone >> nth=0 >> .card >> nth=0", "card-normal"),
    (".state-empty", "state-empty"),
    (".skeleton-line >> nth=0 >> xpath=ancestor::div[2]", "state-skeleton"),
    ("xpath=//div[.//self::*[@class='err-head']]", "state-error"),
]


async def main():
    async with async_playwright() as p:
        browser = await p.chromium.launch()
        ctx = await browser.new_context(
            viewport={"width": 390, "height": 844},
            device_scale_factor=2,
            locale="zh-CN",
        )
        page = await ctx.new_page()
        await page.goto(PROTO, wait_until="networkidle")
        await page.wait_for_timeout(400)

        shot = OUT / "sheet-phone.png"
        await page.locator(".phone").nth(1).screenshot(path=str(shot))
        print(f"OK {shot}")

        # normal card: the FIRST card inside phone 0 (the physiology card)
        shot = OUT / "card-normal.png"
        await page.locator(".phone").nth(0).locator(".card").first.screenshot(
            path=str(shot)
        )
        print(f"OK {shot}")

        # empty state block
        shot = OUT / "state-empty.png"
        await page.locator(".state-empty").screenshot(path=str(shot))
        print(f"OK {shot}")

        # skeleton block: the div containing the three skeleton lines
        shot = OUT / "state-skeleton.png"
        await page.locator("div:has(> .skeleton-line)").first.screenshot(
            path=str(shot)
        )
        print(f"OK {shot}")

        # error block: div containing err-head
        shot = OUT / "state-error.png"
        await page.locator("div:has(> .err-head)").first.screenshot(path=str(shot))
        print(f"OK {shot}")

        await browser.close()
    print("done")


asyncio.run(main())
