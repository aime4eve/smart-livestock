#!/usr/bin/env python3
"""NIX-256 T1b six-form journey (v3, async): UI login, wheel scroll, clip."""
import asyncio
import sys
from pathlib import Path

from playwright.async_api import async_playwright

APP = "http://localhost:8771"
OUT = Path(__file__).resolve().parent / "physiology" / "flutter"
OUT.mkdir(parents=True, exist_ok=True)


async def ui_login(page, phone, password="123"):
    await page.goto(f"{APP}/login", wait_until="domcontentloaded")
    await page.wait_for_timeout(5000)
    for label, text in [("手机号", phone), ("密码", password)]:
        r = await page.evaluate(
            """(lab) => { const el = Array.from(document.querySelectorAll('[aria-label]'))
                .find(n => n.getAttribute('aria-label') === lab);
                const rr = el.getBoundingClientRect(); return {x: rr.x+rr.width/2, y: rr.y+rr.height/2}; }""",
            label,
        )
        await page.mouse.click(r["x"], r["y"])
        await page.wait_for_timeout(400)
        await page.keyboard.type(text, delay=50)
    r = await page.evaluate(
        """() => { const el = Array.from(document.querySelectorAll('[role=button]'))
            .find(n => (n.textContent||'').trim() === '登录');
            const rr = el.getBoundingClientRect(); return {x: rr.x+rr.width/2, y: rr.y+rr.height/2}; }"""
    )
    await page.mouse.click(r["x"], r["y"])
    await page.wait_for_timeout(5000)
    print(f"login {phone} -> {page.url}")


async def node_rect(page, text_start):
    return await page.evaluate(
        """(t) => {
            const nodes = Array.from(document.querySelectorAll('flt-semantics *'));
            const el = nodes.find(n => (n.textContent||'').trim().startsWith(t));
            if (!el) return null;
            const r = el.getBoundingClientRect();
            return {x: r.x, y: r.top, w: r.width, h: r.height};
        }""",
        text_start,
    )


async def scroll_to(page, target="生理记录"):
    for _ in range(20):
        rect = await node_rect(page, target)
        if rect and 40 < rect["y"] < 500:
            return rect
        await page.mouse.wheel(0, 600)
        await page.wait_for_timeout(700)
    return await node_rect(page, target)


async def card_clip(page):
    title = await node_rect(page, "生理记录")
    btn = await node_rect(page, "＋ 记录")
    empty = await node_rect(page, "尚无生理记录")
    err = await node_rect(page, "生理记录暂时不可用")
    if btn:
        bottom = btn["y"] + btn["h"] + 12
    elif empty:
        bottom = empty["y"] + empty["h"] + 60
    elif err:
        bottom = err["y"] + 130
    else:  # skeleton: three lines below header
        bottom = title["y"] + 110
    top = title["y"] - 12
    return {"x": 14, "y": max(0, top), "width": 362, "height": bottom - top}


async def shot_form(page, name):
    await scroll_to(page)
    clip = await card_clip(page)
    await page.wait_for_timeout(600)
    path = OUT / f"{name}.png"
    await page.screenshot(path=str(path), clip=clip)
    print(f"OK {path} clip={clip}")


async def main(stage):
    async with async_playwright() as p:
        browser = await p.chromium.launch()
        ctx = await browser.new_context(
            viewport={"width": 390, "height": 844},
            device_scale_factor=2,
            locale="zh-CN",
        )
        page = await ctx.new_page()

        if stage == "normal":
            await ui_login(page, "13800138000")
            await page.goto(f"{APP}/livestock/12", wait_until="domcontentloaded")
            await page.wait_for_timeout(6000)
            await shot_form(page, "form-normal")
        elif stage == "empty":
            await ui_login(page, "13800138000")
            await page.goto(f"{APP}/livestock/4", wait_until="domcontentloaded")
            await page.wait_for_timeout(6000)
            await shot_form(page, "form-empty")
        elif stage == "skeleton":

            async def slow(route):
                await asyncio.sleep(9)
                await route.continue_()

            await ui_login(page, "13800138000")
            await page.route("**/physiology-events**", slow)
            await page.goto(f"{APP}/livestock/12", wait_until="domcontentloaded")
            await page.wait_for_timeout(7000)
            await scroll_to(page)
            clip = await card_clip(page)
            path = OUT / "form-skeleton.png"
            await page.screenshot(path=str(path), clip=clip)
            print(f"OK {path} clip={clip}")
            await page.unroute("**/physiology-events**")
        elif stage == "error":
            await ui_login(page, "13800138000")
            await page.route(
                "**/physiology-events**",
                lambda route: route.abort("connectionfailed"),
            )
            await page.goto(f"{APP}/livestock/12", wait_until="domcontentloaded")
            await page.wait_for_timeout(6000)
            await shot_form(page, "form-error")
            await page.unroute("**/physiology-events**")
        elif stage == "permission":
            await ui_login(page, "13800138099")
            # api-consumer login does not auto-select a farm; restore it via
            # storage + full reload (boot restore sets ApiClient active farm)
            await page.evaluate(
                "() => localStorage.setItem('flutter.active_farm_id','1')"
            )
            await page.goto(f"{APP}/livestock/12", wait_until="domcontentloaded")
            await page.wait_for_timeout(6000)
            await shot_form(page, "form-permission")
            labels = await page.evaluate(
                "() => Array.from(document.querySelectorAll('[role=button]')).map(n=>(n.textContent||'').trim()).filter(t=>t.includes('记录'))"
            )
            print("add-button present (must be []):", labels)
        elif stage == "sheet":
            await ui_login(page, "13800138000")
            await page.goto(f"{APP}/livestock/4", wait_until="domcontentloaded")
            await page.wait_for_timeout(6000)
            btn = await scroll_to(page)
            await page.mouse.click(btn["x"] + btn["w"] / 2, btn["y"] + btn["h"] / 2)
            await page.wait_for_timeout(2500)
            path = OUT / "form-sheet.png"
            await page.screenshot(path=str(path))
            print(f"OK {path} (full viewport)")
        await browser.close()
    print("done")


if __name__ == "__main__":
    asyncio.run(main(sys.argv[1]))
