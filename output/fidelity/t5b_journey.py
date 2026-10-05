#!/usr/bin/env python3
"""NIX-256 T5b fidelity journey: capture drinking UI elements on the local stack."""
import asyncio
import sys
from pathlib import Path

from playwright.async_api import async_playwright

APP = "http://localhost:8774"
OUT = Path(__file__).resolve().parent / "drinking" / "flutter"
OUT.mkdir(parents=True, exist_ok=True)


async def ui_login(page, phone="13800138000"):
    await page.goto(f"{APP}/login", wait_until="domcontentloaded")
    await page.wait_for_timeout(7000)
    for label, text in [("手机号", phone), ("密码", "123")]:
        r = await page.evaluate(
            """(lab) => { const el = Array.from(document.querySelectorAll('[aria-label]'))
                .find(n => n.getAttribute('aria-label') === lab);
                const rr = el.getBoundingClientRect(); return {x: rr.x+rr.width/2, y: rr.y+rr.height/2}; }""",
            label,
        )
        await page.mouse.click(r["x"], r["y"])
        await page.wait_for_timeout(500)
        await page.keyboard.type(text, delay=60)
    r = await page.evaluate(
        """() => { const el = Array.from(document.querySelectorAll('[role=button]'))
            .find(n => (n.textContent||'').trim() === '登录');
            const rr = el.getBoundingClientRect(); return {x: rr.x+rr.width/2, y: rr.y+rr.height/2}; }"""
    )
    await page.mouse.click(r["x"], r["y"])
    await page.wait_for_timeout(5000)


async def goto_authed(page, path):
    for _ in range(4):
        await page.goto(f"{APP}{path}", wait_until="domcontentloaded")
        await page.wait_for_timeout(6000)
        if "/login" not in page.url:
            return True
        print("  retry (login redirect)")
    return False


async def node_rect(page, t, exact=False):
    # find the SMALLEST semantics node whose text contains the phrase —
    # Flutter merges titles into long container blobs, so startsWith on
    # leaf text rarely matches; shortest-containing wins.
    return await page.evaluate(
        """(t) => {
            const nodes = Array.from(document.querySelectorAll('flt-semantics *'))
                .filter(n => (n.textContent||'').includes(t) && n.getBoundingClientRect().height > 0);
            if (!nodes.length) return null;
            nodes.sort((a, b) => (a.textContent||'').length - (b.textContent||'').length);
            const el = nodes[0];
            const r = el.getBoundingClientRect();
            return {x: +r.x.toFixed(1), y: +r.top.toFixed(1), w: +r.width.toFixed(1), h: +r.height.toFixed(1)};
        }""",
        t,
    )


async def scroll_to(page, t, exact=False, lo=40, hi=600):
    for _ in range(25):
        rect = await node_rect(page, t, exact)
        if rect and lo < rect["y"] < hi:
            return rect
        await page.mouse.wheel(0, 600)
        await page.wait_for_timeout(700)
    return await node_rect(page, t, exact)


async def clip_shot(page, name, x, y, w, h):
    await page.wait_for_timeout(500)
    path = OUT / f"{name}.png"
    await page.screenshot(path=str(path), clip={"x": x, "y": max(0, y), "width": w, "height": h})
    print(f"OK {name} clip=({x},{max(0,y)},{w},{h})")


async def main(stage):
    async with async_playwright() as p:
        browser = await p.chromium.launch()
        ctx = await browser.new_context(
            viewport={"width": 390, "height": 844}, device_scale_factor=2, locale="zh-CN"
        )
        page = await ctx.new_page()
        await ui_login(page)

        if stage == "card":
            ok = await goto_authed(page, "/livestock/4")
            print("page:", ok, page.url)
            title = await scroll_to(page, "饮水行为")
            print("card title:", title)
            # card bottom: find the last element — fever context or subtitle
            if title["h"] > 150:
                # the matched node is the whole card container — use it directly
                await clip_shot(page, "card-normal", 14, title["y"] - 12, 362, title["h"] + 24)
            else:
                ctx_note = await node_rect(page, "发热")
                sub = await node_rect(page, "同类")
                bottom_anchor = ctx_note or sub
                bottom = (bottom_anchor["y"] + bottom_anchor["h"] + 16) if bottom_anchor else title["y"] + 240
                await clip_shot(page, "card-normal", 14, title["y"] - 12, 362, bottom - (title["y"] - 12))
            await page.screenshot(path=str(OUT / "page-context.png"))
        elif stage == "detail":
            ok = await goto_authed(page, "/livestock/4")
            t = await scroll_to(page, "今日饮水时刻分布")
            card_top = t["y"] - 26
            await clip_shot(page, "chart-distribution", 14, card_top, 362, 240)
            t2 = await scroll_to(page, "48h")
            await clip_shot(page, "chart-overlay", 14, t2["y"] - 26, 362, 260)
            t3 = await scroll_to(page, "数据为瘤胃温度自动检测")
            await clip_shot(page, "note-box", 14, t3["y"] - 12, 362, 90)
            # marking list
            t4 = await scroll_to(page, "饮水事件")
            await page.screenshot(path=str(OUT / "marking-list.png"))
            print("marking list shot (full viewport)")
        elif stage == "fever-layer":
            ok = await goto_authed(page, "/livestock/4")
            t = await scroll_to(page, "体温曲线")
            chips = await node_rect(page, "饮水事件 ✓")
            bottom = (chips["y"] + chips["h"] + 30) if chips else t["y"] + 240
            await clip_shot(page, "fever-layer-card", 14, t["y"] - 26, 362, bottom - (t["y"] - 26))
        elif stage == "building":
            ok = await goto_authed(page, "/livestock/12")
            t = await scroll_to(page, "基线建立中")
            if not t:
                t = await scroll_to(page, "饮水行为")
            print("state anchor:", t)
            await clip_shot(page, "state-building", 14, t["y"] - 60, 362, 220)
        elif stage == "skeleton":
            async def slow(route):
                await asyncio.sleep(9)
                await route.continue_()
            await page.route("**/drinking-summary**", slow)
            await page.route("**/drinking-events**", slow)
            ok = await goto_authed(page, "/livestock/4")
            await page.wait_for_timeout(7000)
            t = await scroll_to(page, "饮水行为")
            await clip_shot(page, "state-skeleton", 14, t["y"] - 12, 362, 160)
            await page.unroute("**/drinking-summary**")
            await page.unroute("**/drinking-events**")
        elif stage == "error":
            await page.route("**/drinking-summary**", lambda r: r.abort("connectionfailed"))
            await page.route("**/drinking-events**", lambda r: r.abort("connectionfailed"))
            ok = await goto_authed(page, "/livestock/4")
            await page.wait_for_timeout(6000)
            t = await scroll_to(page, "饮水数据暂时不可用")
            if not t:
                t = await scroll_to(page, "饮水行为")
            await clip_shot(page, "state-error", 14, t["y"] - 60, 362, 220)
            await page.unroute("**/drinking-summary**")
            await page.unroute("**/drinking-events**")
        elif stage == "locked":
            async def deny(route):
                await route.fulfill(status=403, content_type="application/json",
                    body='{"code":"AUTH_FORBIDDEN","message":"forbidden","data":null}')
            await page.route("**/drinking-peer-comparison**", deny)
            ok = await goto_authed(page, "/livestock/4")
            t = await scroll_to(page, "饮水行为")
            ctx_note = await node_rect(page, "升级")
            bottom = (ctx_note["y"] + ctx_note["h"] + 20) if ctx_note else t["y"] + 260
            await clip_shot(page, "card-locked", 14, t["y"] - 12, 362, bottom - (t["y"] - 12))
            await page.unroute("**/drinking-peer-comparison**")
        await browser.close()
    print("done")


asyncio.run(main(sys.argv[1] if len(sys.argv) > 1 else "card"))
