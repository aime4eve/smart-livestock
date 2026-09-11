# Design Tokens (extracted from prototype)

Source: `docs/marketing/datagen-console-prototype.html`

## CSS Custom Properties (:root)

| Token | CSS Value | Category | Flutter Equivalent |
|-------|-----------|----------|-------------------|
| `--border` | `#D7D2C6` | Color | `Color(0xFFD7D2C6)` |
| `--border-strong` | `#B9B2A2` | Color | `Color(0xFFB9B2A2)` |
| `--danger` | `#B3352C` | Color | `Color(0xFFB3352C)` |
| `--danger-soft` | `#FBE8E6` | Color | `Color(0xFFFBE8E6)` |
| `--info` | `#315F79` | Color | `Color(0xFF315F79)` |
| `--info-soft` | `#E7F1F6` | Color | `Color(0xFFE7F1F6)` |
| `--lg` | `16px` | Spacing | `16` |
| `--md` | `12px` | Spacing | `12` |
| `--primary` | `#2F6B3B` | Color | `Color(0xFF2F6B3B)` |
| `--primary-dark` | `#244F2D` | Color | `Color(0xFF244F2D)` |
| `--primary-soft` | `#E3F0E4` | Color | `Color(0xFFE3F0E4)` |
| `--radius-lg` | `8px` | Spacing | `8` |
| `--radius-md` | `6px` | Spacing | `6` |
| `--radius-sm` | `4px` | Spacing | `4` |
| `--shadow-md` | `0 3px 10px rgba(38,49,38,.14)` | Color | `0 3px 10px rgba(38,49,38,.14)` |
| `--shadow-sm` | `0 1px 3px rgba(38,49,38,.10)` | Color | `0 1px 3px rgba(38,49,38,.10)` |
| `--sm` | `8px` | Spacing | `8` |
| `--success` | `#2F7D44` | Color | `Color(0xFF2F7D44)` |
| `--success-soft` | `#E4F3E8` | Color | `Color(0xFFE4F3E8)` |
| `--surface` | `#F8F6F0` | Color | `Color(0xFFF8F6F0)` |
| `--surface-alt` | `#FFFFFF` | Color | `Color(0xFFFFFFFF)` |
| `--surface-muted` | `#F2F0EA` | Color | `Color(0xFFF2F0EA)` |
| `--text-disabled` | `#98A29A` | Color | `Color(0xFF98A29A)` |
| `--text-primary` | `#263126` | Color | `Color(0xFF263126)` |
| `--text-secondary` | `#617061` | Color | `Color(0xFF617061)` |
| `--warning` | `#B36A16` | Color | `Color(0xFFB36A16)` |
| `--warning-soft` | `#FFF2DE` | Color | `Color(0xFFFFF2DE)` |
| `--xl` | `24px` | Spacing | `24` |
| `--xs` | `4px` | Spacing | `4` |

## Component-Level Styles (key selectors)

| Selector | Property | Value |
|----------|----------|-------|
| `.topbar` | `padding` | `0 var(--xl)` |
| `.topbar` | `box-shadow` | `var(--shadow-md)` |
| `.topbar` | `color` | `#fff` |
| `.topbar` | `background` | `var(--primary)` |
| `.topbar` | `height` | `56px` |
| `.topbar strong` | `font-size` | `17px` |
| `.topbar strong` | `font-weight` | `650` |
| `.topbar-meta` | `font-size` | `12px` |
| `.topbar-meta` | `gap` | `var(--md)` |
| `.proto-chip` | `border-radius` | `var(--radius-md)` |
| `.proto-chip` | `padding` | `3px 8px` |
| `.proto-chip` | `background` | `rgba(255,255,255,.18)` |
| `.side` | `padding` | `var(--lg)` |
| `.side` | `gap` | `var(--lg)` |
| `.side` | `background` | `#FBFAF7` |
| `.side-title` | `font-size` | `12px` |
| `.side-title` | `font-weight` | `700` |
| `.side-title` | `color` | `var(--text-secondary)` |
| `.entry-card` | `border-radius` | `var(--radius-lg)` |
| `.entry-card` | `background` | `var(--surface-alt)` |
| `.entry-card` | `border` | `1px solid var(--border)` |
| `.entry-head` | `padding` | `10px var(--md)` |
| `.entry-head` | `background` | `#fff` |
| `.role` | `font-size` | `11px` |
| `.role` | `font-weight` | `700` |
| `.role` | `border-radius` | `var(--radius-sm)` |
| `.role` | `padding` | `2px 6px` |
| `.role` | `color` | `var(--info)` |
| `.role` | `background` | `var(--info-soft)` |
| `.entry-body` | `padding` | `var(--md)` |
| `.entry-body` | `gap` | `6px` |
| `.rail` | `font-size` | `12px` |
| `.rail` | `gap` | `6px` |
| `.rail` | `color` | `var(--text-secondary)` |
| `.active` | `font-weight` | `700` |
| `.active` | `color` | `var(--primary)` |
| `.entry-note` | `font-size` | `11px` |
| `.entry-note` | `color` | `var(--text-secondary)` |
| `.scope-card` | `border-radius` | `var(--radius-lg)` |
| `.scope-card` | `padding` | `var(--md)` |
| `.scope-card` | `background` | `#fff` |
| `.scope-card` | `border` | `1px solid var(--border)` |
| `.scope-list` | `font-size` | `12px` |
| `.scope-list` | `gap` | `6px` |
| `.scope-list` | `color` | `var(--text-secondary)` |
| `.scope-list b` | `font-weight` | `650` |
| `.scope-list b` | `color` | `var(--text-primary)` |
| `.content` | `padding` | `var(--xl)` |
| `.content` | `width` | `0` |
| `.console` | `border-radius` | `var(--radius-lg)` |
| `.console` | `margin` | `0 auto` |
| `.console` | `box-shadow` | `var(--shadow-sm)` |
| `.console` | `background` | `var(--surface-alt)` |
| `.console` | `border` | `1px solid var(--border)` |
| `.console` | `width` | `1180px` |
| `.console` | `height` | `100%` |
| `.console-head` | `padding` | `var(--lg) var(--xl)` |
| `.console-head` | `gap` | `var(--lg)` |
| `.console-head` | `background` | `#fff` |
| `.console-title h1` | `font-size` | `20px` |
| `.console-title h1` | `font-weight` | `700` |
| `.console-title p` | `font-size` | `12px` |
| `.console-title p` | `color` | `var(--text-secondary)` |
| `.status-pill` | `font-size` | `12px` |
| `.status-pill` | `font-weight` | `700` |
| `.status-pill` | `border-radius` | `999px` |
| `.status-pill` | `padding` | `4px 10px` |
| `.status-pill` | `gap` | `7px` |
| `.status-pill` | `color` | `var(--success)` |
| `.status-pill` | `background` | `var(--success-soft)` |
| `.stop` | `color` | `var(--text-secondary)` |
| `.stop` | `background` | `var(--surface-muted)` |
| `.dot` | `border-radius` | `50%` |
| `.dot` | `background` | `currentColor` |
| `.dot` | `width` | `8px` |
| `.dot` | `height` | `8px` |
| `.switch` | `border-radius` | `999px` |
| `.switch` | `padding` | `2px` |
| `.switch` | `background` | `#fff` |
| `.switch` | `border` | `1px solid var(--border-strong)` |
| `.switch` | `width` | `46px` |
| `.switch` | `height` | `26px` |
| `.switch span` | `border-radius` | `50%` |
| `.switch span` | `background` | `var(--border-strong)` |
| `.switch span` | `width` | `20px` |
| `.switch span` | `height` | `20px` |
| `.on` | `color` | `var(--primary)` |
| `.on` | `background` | `var(--primary)` |
| `.field label` | `font-size` | `11px` |
| `.field label` | `font-weight` | `650` |
| `.field label` | `color` | `var(--text-secondary)` |
| `.select` | `font-size` | `13px` |
| `.select` | `border-radius` | `var(--radius-md)` |
| `.select` | `padding` | `0 9px` |
| `.select` | `color` | `var(--text-primary)` |
| `.select` | `background` | `#fff` |
| `.select` | `border` | `1px solid var(--border)` |
| `.select` | `width` | `100%` |
| `.select` | `height` | `34px` |
| `.select:focus` | `box-shadow` | `0 0 0 2px var(--primary-soft)` |
| `.select:focus` | `color` | `var(--primary)` |
| `.tab` | `font-size` | `13px` |
| `.tab` | `font-weight` | `600` |
| `.tab` | `color` | `var(--text-secondary)` |
| `.tab` | `background` | `transparent` |
| `.tab` | `border` | `0` |
| `.tab` | `height` | `42px` |
| `.tab[aria-selected=true]` | `color` | `var(--primary)` |
| `.tab[aria-selected=true]` | `background` | `#FFFEFB` |
| `.metric` | `border-radius` | `var(--radius-lg)` |
| `.metric` | `padding` | `var(--md)` |
| `.metric` | `background` | `#fff` |
| `.metric` | `border` | `1px solid var(--border)` |
| `.metric label` | `font-size` | `11px` |
| `.metric label` | `font-weight` | `650` |
| `.metric label` | `color` | `var(--text-secondary)` |
| `.metric strong` | `font-size` | `22px` |
| `.metric strong` | `height` | `1.2` |
| `.metric small` | `font-size` | `11px` |
| `.metric small` | `color` | `var(--text-secondary)` |
| `.section` | `border-radius` | `var(--radius-lg)` |
| `.section` | `background` | `#fff` |
| `.section` | `border` | `1px solid var(--border)` |
| `.section-head` | `padding` | `10px var(--lg)` |
| `.section-head` | `gap` | `var(--lg)` |
| `.section-head` | `background` | `#fff` |
| `.section-head` | `height` | `48px` |
| `.section-head h2` | `font-size` | `14px` |
| `.section-head h2` | `font-weight` | `700` |
| `.section-head p` | `font-size` | `11px` |
| `.section-head p` | `color` | `var(--text-secondary)` |
| `.btn` | `font-size` | `13px` |
| `.btn` | `font-weight` | `650` |
| `.btn` | `border-radius` | `var(--radius-md)` |
| `.btn` | `padding` | `0 12px` |
| `.btn` | `color` | `var(--text-primary)` |
| `.btn` | `background` | `#fff` |
| `.btn` | `border` | `1px solid var(--border)` |
| `.btn` | `height` | `34px` |
| `.primary` | `color` | `var(--primary)` |
| `.primary` | `background` | `var(--primary)` |
| `.danger` | `color` | `var(--danger)` |
| `.danger` | `background` | `var(--danger)` |
| `.ghost-danger` | `color` | `var(--danger)` |
| `.ghost-danger` | `background` | `#fff` |
| `.btn:disabled` | `color` | `var(--border)` |
| `.btn:disabled` | `background` | `var(--surface-muted)` |
| `.checkbox` | `color` | `var(--primary)` |
| `.checkbox` | `width` | `16px` |
| `.checkbox` | `height` | `16px` |
| `.tag` | `font-size` | `11px` |
| `.tag` | `font-weight` | `700` |
| `.tag` | `border-radius` | `4px` |
| `.tag` | `padding` | `0 7px` |
| `.tag` | `height` | `20px` |
| `.green` | `color` | `var(--success)` |
| `.green` | `background` | `var(--success-soft)` |
| `.gray` | `color` | `var(--text-secondary)` |
| `.gray` | `background` | `var(--surface-muted)` |
| `.red` | `color` | `var(--danger)` |
| `.red` | `background` | `var(--danger-soft)` |
| `.blue` | `color` | `var(--info)` |
| `.blue` | `background` | `var(--info-soft)` |
| `.amber` | `color` | `var(--warning)` |
| `.amber` | `background` | `var(--warning-soft)` |
| `.bulkbar` | `padding` | `10px var(--lg)` |
| `.bulkbar` | `gap` | `var(--md)` |
| `.bulkbar` | `background` | `var(--surface-muted)` |
| `.option` | `border-radius` | `var(--radius-md)` |
| `.option` | `padding` | `10px` |
| `.option` | `background` | `#fff` |
| `.option` | `border` | `1px solid var(--border)` |
| `.option label` | `font-size` | `13px` |
| `.option label` | `font-weight` | `650` |
| `.option small` | `font-size` | `11px` |
| `.option small` | `color` | `var(--text-secondary)` |
| `.active` | `box-shadow` | `0 0 0 2px var(--primary-soft)` |
| `.active` | `background` | `#FBFDFB` |
| `.summary-row span` | `font-size` | `12px` |
| `.summary-row span` | `font-weight` | `650` |
| `.summary-row span` | `color` | `var(--text-secondary)` |
| `.warning-band` | `font-size` | `12px` |
| `.warning-band` | `border-radius` | `var(--radius-sm)` |
| `.warning-band` | `padding` | `10px 12px` |
| `.warning-band` | `color` | `#754713` |
| `.warning-band` | `background` | `var(--warning-soft)` |
| `.danger-band` | `font-size` | `12px` |
| `.danger-band` | `border-radius` | `var(--radius-sm)` |
| `.danger-band` | `padding` | `10px 12px` |
| `.danger-band` | `color` | `#7D2721` |
| `.danger-band` | `background` | `var(--danger-soft)` |
| `.audit-item` | `font-size` | `12px` |
| `.audit-item` | `padding` | `12px var(--lg)` |
| `.audit-item` | `gap` | `var(--md)` |
| `.audit-item` | `background` | `#fff` |
| `.modal-back` | `padding` | `var(--xl)` |
| `.modal-back` | `background` | `rgba(38,49,38,.38)` |
| `.modal` | `border-radius` | `var(--radius-lg)` |
| `.modal` | `box-shadow` | `var(--shadow-md)` |
| `.modal` | `background` | `#fff` |
| `.modal` | `width` | `min(520px,100%)` |
| `.modal-body` | `padding` | `var(--lg)` |
| `.modal-body` | `gap` | `var(--md)` |
| `.modal-row` | `font-size` | `12px` |
| `.modal-row` | `gap` | `var(--md)` |
| `.modal-row span` | `font-weight` | `650` |
| `.modal-row span` | `color` | `var(--text-secondary)` |
| `.confirm-input` | `font-size` | `13px` |
| `.confirm-input` | `border-radius` | `var(--radius-md)` |
| `.confirm-input` | `padding` | `0 10px` |
| `.confirm-input` | `border` | `1px solid var(--border)` |
| `.confirm-input` | `width` | `100%` |
| `.confirm-input` | `height` | `36px` |
| `.modal-actions` | `padding` | `var(--lg)` |
| `.modal-actions` | `gap` | `var(--sm)` |
| `.modal-actions` | `background` | `var(--surface)` |
| `.confirmation` | `border-radius` | `var(--radius-lg)` |
| `.confirmation` | `padding` | `var(--lg)` |
| `.confirmation` | `background` | `#FFFEFB` |
| `.confirmation` | `border` | `1px dashed var(--border-strong)` |
| `.confirmation` | `width` | `1180px` |
| `.confirmation ul` | `font-size` | `13px` |
| `.confirmation ul` | `gap` | `8px` |
| `.confirmation input` | `color` | `var(--primary)` |
| `.confirmation input` | `width` | `16px` |
| `.confirmation input` | `height` | `16px` |
| `.footer` | `font-size` | `11px` |
| `.footer` | `padding` | `14px var(--xl)` |
| `.footer` | `color` | `var(--text-secondary)` |
