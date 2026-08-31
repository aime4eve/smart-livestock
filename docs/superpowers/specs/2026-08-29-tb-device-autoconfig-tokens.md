# Design Tokens (extracted from prototype)

Source: `docs/marketing/2026-08-29-tb-device-autoconfig-wizard.html`

## CSS Custom Properties (:root)

| Token | CSS Value | Category | Flutter Equivalent |
|-------|-----------|----------|-------------------|
| `--border` | `#D7D2C6` | Color | `Color(0xFFD7D2C6)` |
| `--danger` | `#C2564B` | Color | `Color(0xFFC2564B)` |
| `--danger-soft` | `#FBE8E6` | Color | `Color(0xFFFBE8E6)` |
| `--info` | `#4A7F9D` | Color | `Color(0xFF4A7F9D)` |
| `--info-soft` | `#E7F1F6` | Color | `Color(0xFFE7F1F6)` |
| `--lg` | `16px` | Spacing | `16` |
| `--md` | `12px` | Spacing | `12` |
| `--primary` | `#2F6B3B` | Color | `Color(0xFF2F6B3B)` |
| `--primary-dark` | `#244F2D` | Color | `Color(0xFF244F2D)` |
| `--primary-soft` | `#E3F0E4` | Color | `Color(0xFFE3F0E4)` |
| `--radius` | `8px` | Radius | `8` |
| `--shadow` | `0 1px 3px rgba(38, 49, 38, 0.12)` | Color | `0 1px 3px rgba(38, 49, 38, 0.12)` |
| `--sm` | `8px` | Spacing | `8` |
| `--success` | `#4C9A5F` | Color | `Color(0xFF4C9A5F)` |
| `--success-soft` | `#E4F3E8` | Color | `Color(0xFFE4F3E8)` |
| `--surface` | `#F8F6F0` | Color | `Color(0xFFF8F6F0)` |
| `--surface-alt` | `#FFFFFF` | Color | `Color(0xFFFFFFFF)` |
| `--surface-muted` | `#F2F0EA` | Color | `Color(0xFFF2F0EA)` |
| `--text-primary` | `#263126` | Color | `Color(0xFF263126)` |
| `--text-secondary` | `#617061` | Color | `Color(0xFF617061)` |
| `--warning` | `#D28A2D` | Color | `Color(0xFFD28A2D)` |
| `--warning-soft` | `#FFF2DE` | Color | `Color(0xFFFFF2DE)` |
| `--xl` | `24px` | Spacing | `24` |
| `--xs` | `4px` | Spacing | `4` |

## Component-Level Styles (key selectors)

| Selector | Property | Value |
|----------|----------|-------|
| `.phone` | `margin` | `0 auto` |
| `.phone` | `background` | `var(--surface)` |
| `.phone` | `width` | `390px` |
| `.phone` | `height` | `780px` |
| `.handle` | `border-radius` | `2px` |
| `.handle` | `margin` | `0 auto var(--md)` |
| `.handle` | `background` | `var(--border)` |
| `.handle` | `width` | `40px` |
| `.handle` | `height` | `4px` |
| `.step` | `font-size` | `12px` |
| `.step` | `font-weight` | `600` |
| `.step` | `border-radius` | `50%` |
| `.step` | `color` | `var(--text-secondary)` |
| `.step` | `border` | `1px solid var(--border)` |
| `.step` | `width` | `24px` |
| `.step` | `height` | `24px` |
| `.active` | `color` | `var(--primary)` |
| `.active` | `background` | `var(--primary)` |
| `.line` | `background` | `var(--border)` |
| `.line` | `height` | `1px` |
| `.card` | `border-radius` | `var(--radius)` |
| `.card` | `padding` | `var(--md)` |
| `.card` | `box-shadow` | `var(--shadow)` |
| `.card` | `background` | `var(--surface-alt)` |
| `.card` | `border` | `1px solid var(--border)` |
| `.row` | `font-size` | `13px` |
| `.row` | `gap` | `var(--md)` |
| `.badge` | `font-size` | `12px` |
| `.badge` | `font-weight` | `600` |
| `.badge` | `border-radius` | `4px` |
| `.badge` | `padding` | `0 var(--sm)` |
| `.badge` | `height` | `22px` |
| `.success` | `color` | `var(--success)` |
| `.success` | `background` | `var(--success-soft)` |
| `.warning` | `color` | `var(--warning)` |
| `.warning` | `background` | `var(--warning-soft)` |
| `.danger` | `color` | `var(--danger)` |
| `.danger` | `background` | `var(--danger-soft)` |
| `.info` | `color` | `var(--info)` |
| `.info` | `background` | `var(--info-soft)` |
| `.button` | `font-size` | `15px` |
| `.button` | `font-weight` | `600` |
| `.button` | `border-radius` | `var(--radius)` |
| `.button` | `border` | `0` |
| `.button` | `height` | `46px` |
| `.secondary` | `color` | `var(--text-primary)` |
| `.secondary` | `background` | `var(--surface-muted)` |
| `.primary` | `color` | `#fff` |
| `.primary` | `background` | `var(--primary)` |
| `.note` | `font-size` | `13px` |
| `.note` | `border-radius` | `0 var(--radius) var(--radius) 0` |
| `.note` | `padding` | `var(--md)` |
| `.note` | `color` | `var(--text-primary)` |
| `.note` | `background` | `var(--warning-soft)` |
| `.note` | `height` | `1.45` |
| `.state` | `font-size` | `12px` |
| `.state` | `border-radius` | `var(--radius)` |
| `.state` | `padding` | `var(--sm)` |
| `.state` | `color` | `var(--text-secondary)` |
| `.state` | `background` | `var(--surface-alt)` |
| `.state` | `border` | `1px solid var(--border)` |
| `.state strong` | `font-size` | `13px` |
| `.state strong` | `color` | `var(--text-primary)` |
