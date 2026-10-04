# Design Tokens (extracted from prototype)

Source: `docs/prototypes/drinking-event-detection-prototype.html`

## CSS Custom Properties (:root)

| Token | CSS Value | Category | Flutter Equivalent |
|-------|-----------|----------|-------------------|
| `--accent` | `#8BA95A` | Color | `Color(0xFF8BA95A)` |
| `--border` | `#D7D2C6` | Color | `Color(0xFFD7D2C6)` |
| `--danger` | `#C2564B` | Color | `Color(0xFFC2564B)` |
| `--digestive` | `#8D6E4F` | Other | `#8D6E4F` |
| `--drinking` | `#3D7FA8` | Other | `#3D7FA8` |
| `--drinking-event` | `#2C6486` | Other | `#2C6486` |
| `--drinking-soft` | `#E2EDF4` | Other | `#E2EDF4` |
| `--epidemic` | `#2E7D74` | Other | `#2E7D74` |
| `--estrus` | `#C25689` | Other | `#C25689` |
| `--fever` | `#D97B29` | Other | `#D97B29` |
| `--info` | `#4A7F9D` | Color | `Color(0xFF4A7F9D)` |
| `--lg` | `16px` | Spacing | `16` |
| `--map-fence` | `#2F6B3B` | Other | `#2F6B3B` |
| `--map-green` | `#DCE8D5` | Other | `#DCE8D5` |
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
| `.flow-grid` | `gap` | `28px` |
| `.flow-grid` | `width` | `2000px` |
| `.screen-label` | `font-size` | `13px` |
| `.screen-label` | `font-weight` | `700` |
| `.screen-label` | `gap` | `6px` |
| `.screen-label` | `color` | `var(--primary)` |
| `.num` | `font-size` | `12px` |
| `.num` | `font-weight` | `700` |
| `.num` | `border-radius` | `50%` |
| `.num` | `color` | `#fff` |
| `.num` | `background` | `var(--primary)` |
| `.num` | `width` | `22px` |
| `.num` | `height` | `22px` |
| `.screen-sublabel` | `font-size` | `11px` |
| `.screen-sublabel` | `color` | `var(--text-secondary)` |
| `.screen-sublabel` | `width` | `300px` |
| `.screen-sublabel` | `height` | `1.4` |
| `.phone-shell` | `border-radius` | `24px` |
| `.phone-shell` | `box-shadow` | `var(--shadow-elev)` |
| `.phone-shell` | `background` | `var(--surface)` |
| `.phone-shell` | `border` | `1px solid var(--border)` |
| `.phone-shell` | `width` | `280px` |
| `.status-bar` | `font-size` | `10px` |
| `.status-bar` | `font-weight` | `600` |
| `.status-bar` | `padding` | `6px 14px` |
| `.status-bar` | `color` | `var(--text-primary)` |
| `.status-bar` | `background` | `var(--surface-alt)` |
| `.nav-bar` | `padding` | `10px 12px` |
| `.nav-bar` | `gap` | `8px` |
| `.nav-bar` | `background` | `var(--surface-alt)` |
| `.back` | `font-size` | `15px` |
| `.back` | `color` | `var(--text-primary)` |
| `.title` | `font-size` | `14px` |
| `.title` | `font-weight` | `700` |
| `.screen-body` | `padding` | `12px` |
| `.screen-body` | `gap` | `10px` |
| `.screen-body` | `height` | `520px` |
| `.card` | `border-radius` | `var(--radius-md)` |
| `.card` | `padding` | `12px` |
| `.card` | `box-shadow` | `var(--shadow-card)` |
| `.card` | `background` | `var(--surface-alt)` |
| `.section-title` | `font-size` | `12px` |
| `.section-title` | `font-weight` | `700` |
| `.section-title` | `gap` | `6px` |
| `.section-title` | `color` | `var(--text-primary)` |
| `.dot` | `border-radius` | `50%` |
| `.dot` | `width` | `8px` |
| `.dot` | `height` | `8px` |
| `.chip` | `font-size` | `10px` |
| `.chip` | `font-weight` | `600` |
| `.chip` | `border-radius` | `999px` |
| `.chip` | `padding` | `3px 8px` |
| `.chip` | `gap` | `4px` |
| `.drinking` | `color` | `var(--drinking)` |
| `.drinking` | `background` | `var(--drinking-soft)` |
| `.normal` | `color` | `var(--primary)` |
| `.normal` | `background` | `var(--primary-soft)` |
| `.fever` | `color` | `var(--fever)` |
| `.fever` | `background` | `rgba(217,123,41,.12)` |
| `.muted` | `color` | `var(--text-secondary)` |
| `.muted` | `background` | `var(--surface)` |
| `.muted` | `border` | `1px solid var(--border)` |
| `.subtle` | `font-size` | `11px` |
| `.subtle` | `color` | `var(--text-secondary)` |
| `.subtle` | `height` | `1.45` |
| `.title` | `gap` | `6px` |
| `.bignum` | `font-size` | `30px` |
| `.bignum` | `font-weight` | `800` |
| `.bignum` | `color` | `var(--drinking)` |
| `.bignum` | `height` | `1` |
| `.bignum-unit` | `font-size` | `11px` |
| `.bignum-unit` | `color` | `var(--text-secondary)` |
| `.v` | `font-size` | `12px` |
| `.v` | `font-weight` | `700` |
| `.v` | `color` | `var(--text-primary)` |
| `.mini-bars` | `padding` | `0 2px` |
| `.mini-bars` | `gap` | `6px` |
| `.mini-bars` | `height` | `44px` |
| `.bar` | `border-radius` | `4px 4px 2px 2px` |
| `.bar` | `background` | `var(--drinking)` |
| `.bar` | `width` | `100%` |
| `.day` | `font-size` | `8px` |
| `.day` | `color` | `var(--text-secondary)` |
| `.val` | `font-size` | `8px` |
| `.val` | `font-weight` | `700` |
| `.val` | `color` | `var(--text-secondary)` |
| `.context-note` | `border-radius` | `8px` |
| `.context-note` | `padding` | `7px 8px` |
| `.context-note` | `gap` | `6px` |
| `.context-note` | `background` | `rgba(217,123,41,.08)` |
| `.ic` | `font-size` | `11px` |
| `.ic` | `height` | `1.3` |
| `.tx` | `font-size` | `9.5px` |
| `.tx` | `color` | `var(--fever)` |
| `.tx` | `height` | `1.45` |
| `.chart-card` | `border-radius` | `var(--radius-md)` |
| `.chart-card` | `padding` | `12px` |
| `.chart-card` | `box-shadow` | `var(--shadow-card)` |
| `.chart-card` | `background` | `var(--surface-alt)` |
| `.chart-title` | `font-size` | `11px` |
| `.chart-title` | `font-weight` | `700` |
| `.right` | `font-size` | `9px` |
| `.right` | `font-weight` | `600` |
| `.right` | `color` | `var(--text-secondary)` |
| `.chart-area` | `border-radius` | `8px` |
| `.chart-area` | `padding` | `8px` |
| `.chart-area` | `background` | `var(--surface)` |
| `.chart` | `width` | `100%` |
| `.chart` | `height` | `auto` |
| `.lg` | `font-size` | `8.5px` |
| `.lg` | `gap` | `4px` |
| `.lg` | `color` | `var(--text-secondary)` |
| `.swatch` | `border-radius` | `3px` |
| `.swatch` | `width` | `10px` |
| `.swatch` | `height` | `10px` |
| `.seg` | `border-radius` | `999px` |
| `.seg` | `padding` | `2px` |
| `.seg` | `background` | `var(--surface)` |
| `.seg` | `border` | `1px solid var(--border)` |
| `.opt` | `font-size` | `9px` |
| `.opt` | `font-weight` | `600` |
| `.opt` | `border-radius` | `999px` |
| `.opt` | `padding` | `3px 7px` |
| `.opt` | `color` | `var(--text-secondary)` |
| `.on` | `color` | `#fff` |
| `.on` | `background` | `var(--drinking)` |
| `.note-box` | `border-radius` | `8px` |
| `.note-box` | `padding` | `9px 10px` |
| `.note-box` | `gap` | `7px` |
| `.note-box` | `background` | `rgba(61,127,168,.07)` |
| `.icon` | `font-size` | `13px` |
| `.icon` | `color` | `var(--drinking)` |
| `.icon` | `height` | `1.2` |
| `.text` | `font-size` | `9.5px` |
| `.text` | `color` | `var(--drinking)` |
| `.text` | `height` | `1.5` |
| `.state-card` | `padding` | `18px 12px` |
| `.state-card` | `gap` | `8px` |
| `.t` | `font-size` | `12px` |
| `.t` | `font-weight` | `700` |
| `.d` | `font-size` | `10px` |
| `.d` | `color` | `var(--text-secondary)` |
| `.d` | `height` | `1.5` |
| `.premium-strip` | `border-radius` | `8px` |
| `.premium-strip` | `padding` | `7px 9px` |
| `.premium-strip` | `gap` | `6px` |
| `.premium-strip` | `background` | `linear-gradient(90deg,rgba(61,127,168,.10),rgba(61,127,168,.04))` |
| `.premium-strip` | `border` | `1px dashed var(--drinking)` |
| `.lock-tx` | `font-size` | `10px` |
| `.lock-tx` | `padding` | `0 16px` |
| `.lock-tx` | `color` | `var(--text-secondary)` |
| `.lock-tx` | `height` | `1.5` |
| `.upgrade-btn` | `font-size` | `10px` |
| `.upgrade-btn` | `font-weight` | `700` |
| `.upgrade-btn` | `border-radius` | `6px` |
| `.upgrade-btn` | `padding` | `5px 14px` |
| `.upgrade-btn` | `color` | `#fff` |
| `.upgrade-btn` | `background` | `var(--primary)` |
| `.tier-badge` | `font-size` | `8.5px` |
| `.tier-badge` | `font-weight` | `700` |
| `.tier-badge` | `border-radius` | `999px` |
| `.tier-badge` | `padding` | `2px 7px` |
| `.tier-badge` | `color` | `var(--primary)` |
| `.tier-badge` | `background` | `var(--primary-soft)` |
| `.layer-chip` | `font-size` | `9px` |
| `.layer-chip` | `font-weight` | `700` |
| `.layer-chip` | `border-radius` | `999px` |
| `.layer-chip` | `padding` | `3px 8px` |
| `.layer-chip` | `gap` | `4px` |
| `.layer-chip` | `color` | `var(--text-secondary)` |
| `.layer-chip` | `background` | `var(--surface-alt)` |
| `.layer-chip` | `border` | `1px solid var(--border)` |
| `.sw` | `border-radius` | `50%` |
| `.sw` | `width` | `7px` |
| `.sw` | `height` | `7px` |
| `.flow-step` | `padding` | `6px 0` |
| `.flow-step` | `gap` | `8px` |
| `.n` | `font-size` | `9px` |
| `.n` | `font-weight` | `700` |
| `.n` | `border-radius` | `50%` |
| `.n` | `color` | `#fff` |
| `.n` | `background` | `var(--drinking)` |
| `.n` | `width` | `16px` |
| `.n` | `height` | `16px` |
| `.tx small` | `font-size` | `9px` |
| `.tx small` | `color` | `var(--text-secondary)` |
| `.ic` | `border-radius` | `10px` |
| `.ic` | `background` | `var(--drinking-soft)` |
| `.ic` | `width` | `34px` |
| `.t` | `gap` | `6px` |
| `.time` | `font-size` | `8.5px` |
| `.time` | `color` | `var(--text-secondary)` |
| `.skeleton-line` | `border-radius` | `5px` |
| `.skeleton-line` | `background` | `linear-gradient(90deg,var(--surface) 25%,#ECE9E1 50%,var(--surface) 75%)` |
| `.skeleton-line` | `height` | `10px` |
| `.head` | `font-size` | `12px` |
| `.head` | `font-weight` | `700` |
| `.head` | `gap` | `6px` |
| `.head` | `color` | `var(--danger)` |
| `.retry-btn` | `font-size` | `10px` |
| `.retry-btn` | `font-weight` | `700` |
| `.retry-btn` | `border-radius` | `6px` |
| `.retry-btn` | `padding` | `5px 14px` |
| `.retry-btn` | `color` | `#fff` |
| `.retry-btn` | `background` | `var(--danger)` |
| `.spec-panel` | `border-radius` | `var(--radius-lg)` |
| `.spec-panel` | `padding` | `20px 24px` |
| `.spec-panel` | `margin` | `28px auto 0` |
| `.spec-panel` | `box-shadow` | `var(--shadow-card)` |
| `.spec-panel` | `background` | `var(--surface-alt)` |
| `.spec-panel` | `width` | `860px` |
| `.spec-panel h2` | `font-size` | `15px` |
| `.spec-panel h2` | `color` | `var(--primary)` |
| `.spec-panel h3` | `font-size` | `13px` |
| `.spec-panel h3` | `margin` | `14px 0 6px` |
| `.spec-panel h3` | `color` | `var(--text-primary)` |
| `.spec-panel li` | `font-size` | `12px` |
| `.spec-panel li` | `color` | `var(--text-secondary)` |
| `.spec-panel li` | `height` | `1.7` |
| `.spec-panel table` | `font-size` | `11px` |
| `.spec-panel table` | `margin` | `8px 0` |
| `.spec-panel table` | `width` | `100%` |
| `.spec-panel td` | `padding` | `5px 8px` |
| `.spec-panel td` | `border` | `1px solid var(--border)` |
| `.spec-panel th` | `font-weight` | `700` |
| `.spec-panel th` | `background` | `var(--surface)` |
| `.tok` | `font-size` | `10.5px` |
| `.tok` | `border-radius` | `4px` |
| `.tok` | `padding` | `1px 5px` |
| `.tok` | `background` | `var(--surface)` |
