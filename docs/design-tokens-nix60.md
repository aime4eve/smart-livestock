# Design Tokens (extracted from prototype)

Source: `docs/marketing/nix-60-feature-gate-redesign-prototype.html`

## CSS Custom Properties (:root)

| Token | CSS Value | Category | Flutter Equivalent |
|-------|-----------|----------|-------------------|
| `--accent` | `#8BA95A` | Color | `Color(0xFF8BA95A)` |
| `--border` | `#D7D2C6` | Color | `Color(0xFFD7D2C6)` |
| `--danger` | `#C2564B` | Color | `Color(0xFFC2564B)` |
| `--estrus` | `#C25689` | Other | `#C25689` |
| `--info` | `#4A7F9D` | Color | `Color(0xFF4A7F9D)` |
| `--lg` | `16px` | Spacing | `16` |
| `--md` | `12px` | Spacing | `12` |
| `--primary` | `#2F6B3B` | Color | `Color(0xFF2F6B3B)` |
| `--primary-dark` | `#244F2D` | Color | `Color(0xFF244F2D)` |
| `--primary-soft` | `#E3F0E4` | Color | `Color(0xFFE3F0E4)` |
| `--radius-lg` | `16px` | Spacing | `16` |
| `--radius-md` | `12px` | Spacing | `12` |
| `--radius-sm` | `8px` | Spacing | `8` |
| `--shadow-card` | `0 1px 3px rgba(38,49,38,.06),0 1px 2px rgba(38,49,38,.04)` | Color | `0 1px 3px rgba(38,49,38,.06),0 1px 2px rgba(38,49,38,.04)` |
| `--shadow-elev` | `0 4px 16px rgba(38,49,38,.12)` | Color | `0 4px 16px rgba(38,49,38,.12)` |
| `--shadow-sheet` | `0 -4px 24px rgba(38,49,38,.15)` | Color | `0 -4px 24px rgba(38,49,38,.15)` |
| `--sm` | `8px` | Spacing | `8` |
| `--success` | `#4C9A5F` | Color | `Color(0xFF4C9A5F)` |
| `--surface` | `#F8F6F0` | Color | `Color(0xFFF8F6F0)` |
| `--surface-alt` | `#FFFFFF` | Color | `Color(0xFFFFFFFF)` |
| `--text-primary` | `#263126` | Color | `Color(0xFF263126)` |
| `--text-secondary` | `#617061` | Color | `Color(0xFF617061)` |
| `--warning` | `#D28A2D` | Color | `Color(0xFFD28A2D)` |
| `--xl` | `24px` | Spacing | `24` |
| `--xs` | `4px` | Spacing | `4` |
| `--xxl` | `32px` | Spacing | `32` |

## Component-Level Styles (key selectors)

| Selector | Property | Value |
|----------|----------|-------|
| `.page-title h1` | `font-size` | `22px` |
| `.page-title h1` | `font-weight` | `700` |
| `.page-title p` | `font-size` | `13px` |
| `.page-title p` | `color` | `var(--text-secondary)` |
| `.screen-label` | `font-size` | `14px` |
| `.screen-label` | `font-weight` | `700` |
| `.screen-label` | `gap` | `6px` |
| `.screen-label` | `color` | `var(--primary)` |
| `.num` | `font-size` | `12px` |
| `.num` | `font-weight` | `700` |
| `.num` | `border-radius` | `50%` |
| `.num` | `color` | `#fff` |
| `.num` | `background` | `var(--primary)` |
| `.num` | `width` | `24px` |
| `.num` | `height` | `24px` |
| `.screen-sublabel` | `font-size` | `11px` |
| `.screen-sublabel` | `color` | `var(--text-secondary)` |
| `.screen-sublabel` | `width` | `300px` |
| `.screen-sublabel` | `height` | `1.5` |
| `.phone` | `border-radius` | `36px` |
| `.phone` | `box-shadow` | `0 0 0 8px #1a1a1a,0 0 0 9px #2a2a2a,0 20px 50px rgba(0,0,0,.25)` |
| `.phone` | `background` | `var(--surface)` |
| `.phone` | `width` | `320px` |
| `.phone` | `height` | `640px` |
| `.phone-notch` | `border-radius` | `0 0 16px 16px` |
| `.phone-notch` | `background` | `#1a1a1a` |
| `.phone-notch` | `width` | `100px` |
| `.phone-notch` | `height` | `22px` |
| `.phone-status` | `font-size` | `11px` |
| `.phone-status` | `font-weight` | `600` |
| `.phone-status` | `padding` | `0 20px` |
| `.phone-status` | `height` | `32px` |
| `.icons` | `font-size` | `10px` |
| `.icons` | `gap` | `4px` |
| `.appbar` | `padding` | `8px 12px` |
| `.appbar` | `gap` | `6px` |
| `.appbar` | `color` | `#fff` |
| `.appbar` | `background` | `var(--primary)` |
| `.back` | `font-size` | `18px` |
| `.back` | `width` | `28px` |
| `.appbar h1` | `font-size` | `14px` |
| `.appbar h1` | `font-weight` | `600` |
| `.action` | `font-size` | `10px` |
| `.action` | `border-radius` | `6px` |
| `.action` | `padding` | `4px 8px` |
| `.action` | `color` | `#fff` |
| `.action` | `background` | `rgba(255,255,255,.15)` |
| `.action` | `border` | `none` |
| `.section-head h3` | `font-size` | `11px` |
| `.section-head h3` | `font-weight` | `700` |
| `.section-head h3` | `color` | `var(--text-secondary)` |
| `.count` | `font-size` | `10px` |
| `.count` | `border-radius` | `8px` |
| `.count` | `padding` | `2px 8px` |
| `.count` | `color` | `var(--text-secondary)` |
| `.count` | `background` | `var(--surface-alt)` |
| `.count` | `border` | `1px solid var(--border)` |
| `.hcard` | `border-radius` | `var(--radius-md)` |
| `.hcard` | `box-shadow` | `var(--shadow-card)` |
| `.hcard` | `background` | `var(--surface-alt)` |
| `.chip` | `font-size` | `9px` |
| `.chip` | `font-weight` | `600` |
| `.chip` | `border-radius` | `999px` |
| `.chip` | `padding` | `2px 8px` |
| `.chip` | `gap` | `3px` |
| `.chip` | `height` | `1.4` |
| `.none` | `color` | `var(--success)` |
| `.none` | `background` | `rgba(76,154,95,.12)` |
| `.none` | `border` | `1px solid rgba(76,154,95,.28)` |
| `.limit` | `color` | `var(--primary)` |
| `.limit` | `background` | `rgba(47,107,59,.12)` |
| `.limit` | `border` | `1px solid rgba(47,107,59,.28)` |
| `.lock` | `color` | `var(--danger)` |
| `.lock` | `background` | `rgba(194,86,75,.12)` |
| `.lock` | `border` | `1px solid rgba(194,86,75,.28)` |
| `.filter` | `color` | `var(--info)` |
| `.filter` | `background` | `rgba(74,127,157,.12)` |
| `.filter` | `border` | `1px solid rgba(74,127,157,.28)` |
| `.lock-open` | `color` | `var(--success)` |
| `.lock-open` | `background` | `rgba(76,154,95,.12)` |
| `.lock-open` | `border` | `1px solid rgba(76,154,95,.28)` |
| `.dot` | `border-radius` | `50%` |
| `.dot` | `background` | `currentColor` |
| `.dot` | `width` | `5px` |
| `.dot` | `height` | `5px` |
| `.fc-name` | `font-size` | `13px` |
| `.fc-name` | `font-weight` | `700` |
| `.fc-name` | `color` | `var(--text-primary)` |
| `.fc-key` | `font-size` | `9px` |
| `.fc-key` | `color` | `var(--text-secondary)` |
| `.fc-tier-cell` | `border-radius` | `var(--radius-sm)` |
| `.fc-tier-cell` | `padding` | `6px 4px` |
| `.fc-tier-cell` | `background` | `var(--surface)` |
| `.fc-tier-cell` | `border` | `1px solid transparent` |
| `.fc-tier-label` | `font-size` | `8px` |
| `.fc-tier-label` | `font-weight` | `700` |
| `.fc-tier-label` | `color` | `var(--text-secondary)` |
| `.fc-tier-val` | `font-size` | `14px` |
| `.fc-tier-val` | `font-weight` | `700` |
| `.fc-tier-val` | `height` | `1` |
| `.fc-tier-unit` | `font-size` | `8px` |
| `.fc-tier-unit` | `color` | `var(--text-secondary)` |
| `.fc-tier-toggle` | `border-radius` | `8px` |
| `.fc-tier-toggle` | `margin` | `4px auto 0` |
| `.fc-tier-toggle` | `width` | `28px` |
| `.fc-tier-toggle` | `height` | `16px` |
| `.knob` | `border-radius` | `50%` |
| `.knob` | `box-shadow` | `0 1px 2px rgba(0,0,0,.2)` |
| `.knob` | `background` | `#fff` |
| `.knob` | `width` | `12px` |
| `.knob` | `height` | `12px` |
| `.edit-row label` | `font-size` | `9px` |
| `.edit-row label` | `color` | `var(--text-secondary)` |
| `.edit-row input` | `font-size` | `11px` |
| `.edit-row input` | `border-radius` | `6px` |
| `.edit-row input` | `padding` | `4px 6px` |
| `.edit-row input` | `color` | `var(--text-primary)` |
| `.edit-row input` | `background` | `var(--surface-alt)` |
| `.edit-row input` | `border` | `1px solid var(--border)` |
| `.edit-row input` | `width` | `0` |
| `.save-btn` | `font-size` | `10px` |
| `.save-btn` | `font-weight` | `600` |
| `.save-btn` | `border-radius` | `6px` |
| `.save-btn` | `padding` | `5px 12px` |
| `.save-btn` | `color` | `#fff` |
| `.save-btn` | `background` | `var(--primary)` |
| `.save-btn` | `border` | `none` |
| `.cancel-btn` | `font-size` | `10px` |
| `.cancel-btn` | `border-radius` | `6px` |
| `.cancel-btn` | `padding` | `5px 10px` |
| `.cancel-btn` | `color` | `var(--text-secondary)` |
| `.cancel-btn` | `background` | `var(--surface)` |
| `.cancel-btn` | `border` | `1px solid var(--border)` |
| `.tab-item` | `font-size` | `11px` |
| `.tab-item` | `font-weight` | `600` |
| `.tab-item` | `padding` | `10px 4px` |
| `.tab-item` | `color` | `var(--text-secondary)` |
| `.tab-item` | `background` | `transparent` |
| `.tab-item` | `border` | `none` |
| `.tab-count` | `font-size` | `8px` |
| `.tab-count` | `font-weight` | `500` |
| `.tab-count` | `color` | `var(--text-secondary)` |
| `.lc-card` | `padding` | `10px 12px` |
| `.lc-card` | `gap` | `8px` |
| `.lc-name` | `font-size` | `12px` |
| `.lc-name` | `font-weight` | `600` |
| `.lc-name` | `height` | `1.2` |
| `.lc-meta` | `font-size` | `9px` |
| `.lc-meta` | `gap` | `4px` |
| `.lc-meta` | `color` | `var(--text-secondary)` |
| `.lc-val-num` | `font-size` | `15px` |
| `.lc-val-num` | `font-weight` | `700` |
| `.lc-val-num` | `height` | `1` |
| `.lc-val-unit` | `font-size` | `8px` |
| `.lc-val-unit` | `color` | `var(--text-secondary)` |
| `.lc-toggle` | `border-radius` | `10px` |
| `.lc-toggle` | `width` | `36px` |
| `.lc-toggle` | `height` | `20px` |
| `.lc-icon-btn` | `font-size` | `14px` |
| `.lc-icon-btn` | `border-radius` | `6px` |
| `.lc-icon-btn` | `color` | `var(--text-secondary)` |
| `.lc-icon-btn` | `background` | `transparent` |
| `.lc-icon-btn` | `border` | `none` |
| `.lc-icon-btn` | `width` | `26px` |
| `.lc-icon-btn` | `height` | `26px` |
| `.empty-state` | `padding` | `60px 20px` |
| `.empty-state` | `color` | `var(--text-secondary)` |
