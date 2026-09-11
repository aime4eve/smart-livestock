# Design Tokens (extracted from prototype)

Source: `/Volumes/DEV/00-products-dev/01-solutions/02-smart-livestock/docs/marketing/nix-52-alert-ui-redesign-prototype.html`

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
| `.screen-sublabel` | `width` | `280px` |
| `.screen-sublabel` | `height` | `1.4` |
| `.phone` | `border-radius` | `36px` |
| `.phone` | `box-shadow` | `0 0 0 8px #1a1a1a,0 0 0 9px #2a2a2a,0 20px 50px rgba(0,0,0,.25)` |
| `.phone` | `background` | `var(--surface)` |
| `.phone` | `width` | `280px` |
| `.phone` | `height` | `580px` |
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
| `.appbar` | `padding` | `6px 12px` |
| `.appbar` | `gap` | `6px` |
| `.appbar` | `color` | `#fff` |
| `.appbar` | `background` | `var(--primary)` |
| `.back` | `font-size` | `18px` |
| `.back` | `width` | `28px` |
| `.appbar h1` | `font-size` | `13px` |
| `.appbar h1` | `font-weight` | `600` |
| `.action` | `font-size` | `10px` |
| `.action` | `border-radius` | `6px` |
| `.action` | `padding` | `4px 8px` |
| `.action` | `color` | `#fff` |
| `.action` | `background` | `rgba(255,255,255,.15)` |
| `.action` | `border` | `none` |
| `.map-road` | `border-radius` | `2px` |
| `.map-road` | `box-shadow` | `0 1px 2px rgba(0,0,0,.08)` |
| `.map-road` | `background` | `#FFF` |
| `.map-fence` | `border-radius` | `4px` |
| `.map-fence` | `border` | `2px solid var(--danger)` |
| `.map-marker` | `font-size` | `14px` |
| `.map-marker` | `border-radius` | `50%` |
| `.map-marker` | `box-shadow` | `0 2px 6px rgba(0,0,0,.2)` |
| `.map-marker` | `border` | `2px solid #fff` |
| `.map-marker` | `width` | `28px` |
| `.map-marker` | `height` | `28px` |
| `.map-pulse` | `border-radius` | `50%` |
| `.map-pulse` | `border` | `2px solid var(--danger)` |
| `.map-pulse` | `width` | `40px` |
| `.map-pulse` | `height` | `40px` |
| `.map-sheet` | `border-radius` | `16px 16px 0 0` |
| `.map-sheet` | `box-shadow` | `var(--shadow-sheet)` |
| `.map-sheet` | `background` | `var(--surface-alt)` |
| `.map-sheet` | `height` | `70%` |
| `.map-sheet-handle` | `border-radius` | `2px` |
| `.map-sheet-handle` | `margin` | `8px auto 0` |
| `.map-sheet-handle` | `background` | `var(--border)` |
| `.map-sheet-handle` | `width` | `32px` |
| `.map-sheet-handle` | `height` | `3px` |
| `.sheet-tabs` | `padding` | `4px 12px` |
| `.sheet-tabs` | `gap` | `0` |
| `.sheet-tab` | `font-size` | `10px` |
| `.sheet-tab` | `font-weight` | `600` |
| `.sheet-tab` | `padding` | `7px 4px` |
| `.sheet-tab` | `gap` | `3px` |
| `.sheet-tab` | `color` | `var(--text-secondary)` |
| `.sheet-tab` | `background` | `transparent` |
| `.sheet-tab` | `border` | `none` |
| `.tab-badge` | `font-size` | `8px` |
| `.tab-badge` | `font-weight` | `700` |
| `.tab-badge` | `border-radius` | `6px` |
| `.tab-badge` | `padding` | `0 4px` |
| `.tab-badge` | `color` | `#fff` |
| `.tab-badge` | `background` | `var(--danger)` |
| `.tab-badge` | `width` | `12px` |
| `.dash-row` | `padding` | `8px 12px 4px` |
| `.dash-row` | `gap` | `8px` |
| `.dash-card` | `border-radius` | `10px` |
| `.dash-card` | `padding` | `7px` |
| `.dash-card` | `background` | `var(--surface)` |
| `.dash-card` | `border` | `1px solid var(--border)` |
| `.has-alert` | `color` | `rgba(194,86,75,.3)` |
| `.has-alert` | `background` | `rgba(194,86,75,.03)` |
| `.ico` | `font-size` | `12px` |
| `.ico` | `border-radius` | `6px` |
| `.ico` | `width` | `22px` |
| `.ico` | `height` | `22px` |
| `.danger` | `color` | `var(--danger)` |
| `.danger` | `background` | `rgba(194,86,75,.1)` |
| `.warning` | `color` | `var(--warning)` |
| `.warning` | `background` | `rgba(210,138,45,.1)` |
| `.success` | `color` | `var(--success)` |
| `.success` | `background` | `rgba(76,154,95,.1)` |
| `.info` | `color` | `var(--info)` |
| `.info` | `background` | `rgba(74,127,157,.1)` |
| `.count` | `font-size` | `16px` |
| `.count` | `font-weight` | `700` |
| `.count` | `height` | `1` |
| `.label` | `font-size` | `9px` |
| `.label` | `color` | `var(--text-secondary)` |
| `.badge` | `font-size` | `8px` |
| `.badge` | `font-weight` | `700` |
| `.badge` | `border-radius` | `7px` |
| `.badge` | `padding` | `1px 5px` |
| `.fence-list-hd h3` | `font-size` | `11px` |
| `.fence-list-hd h3` | `font-weight` | `700` |
| `.fence-list-hd h3` | `color` | `var(--text-secondary)` |
| `.fence-add-btn` | `font-size` | `9px` |
| `.fence-add-btn` | `font-weight` | `600` |
| `.fence-add-btn` | `border-radius` | `6px` |
| `.fence-add-btn` | `padding` | `3px 8px` |
| `.fence-add-btn` | `gap` | `3px` |
| `.fence-add-btn` | `color` | `#fff` |
| `.fence-add-btn` | `background` | `var(--info)` |
| `.fence-add-btn` | `border` | `none` |
| `.fence-item` | `padding` | `7px 12px` |
| `.fence-item` | `gap` | `8px` |
| `.fence-color-dot` | `border-radius` | `3px` |
| `.fence-color-dot` | `width` | `12px` |
| `.fence-color-dot` | `height` | `12px` |
| `.fence-item-name` | `font-size` | `11px` |
| `.fence-item-name` | `font-weight` | `600` |
| `.fence-item-name` | `height` | `1.2` |
| `.fence-item-meta` | `font-size` | `9px` |
| `.fence-item-meta` | `color` | `var(--text-secondary)` |
| `.fence-icon-btn` | `font-size` | `13px` |
| `.fence-icon-btn` | `border-radius` | `5px` |
| `.fence-icon-btn` | `background` | `transparent` |
| `.fence-icon-btn` | `border` | `none` |
| `.fence-icon-btn` | `width` | `24px` |
| `.fence-icon-btn` | `height` | `24px` |
| `.alert-banner` | `font-size` | `10px` |
| `.alert-banner` | `font-weight` | `600` |
| `.alert-banner` | `border-radius` | `8px` |
| `.alert-banner` | `padding` | `6px 10px` |
| `.alert-banner` | `gap` | `6px` |
| `.alert-banner` | `box-shadow` | `0 2px 8px rgba(194,86,75,.3)` |
| `.alert-banner` | `color` | `#fff` |
| `.alert-banner` | `background` | `var(--danger)` |
| `.pulse-dot` | `border-radius` | `50%` |
| `.pulse-dot` | `background` | `#fff` |
| `.pulse-dot` | `width` | `8px` |
| `.pulse-dot` | `height` | `8px` |
| `.summary-strip` | `padding` | `8px 12px` |
| `.summary-strip` | `background` | `var(--surface-alt)` |
| `.filter-bar` | `padding` | `6px 12px` |
| `.filter-bar` | `background` | `var(--surface)` |
| `.seg-tabs` | `border-radius` | `6px` |
| `.seg-tabs` | `padding` | `2px` |
| `.seg-tabs` | `gap` | `2px` |
| `.seg-tabs` | `background` | `var(--border)` |
| `.seg-tab` | `font-size` | `10px` |
| `.seg-tab` | `font-weight` | `500` |
| `.seg-tab` | `border-radius` | `4px` |
| `.seg-tab` | `padding` | `5px 0` |
| `.seg-tab` | `gap` | `2px` |
| `.seg-tab` | `color` | `var(--text-secondary)` |
| `.seg-tab` | `background` | `transparent` |
| `.seg-tab` | `border` | `none` |
| `.active` | `font-weight` | `600` |
| `.active` | `box-shadow` | `var(--shadow-card)` |
| `.active` | `color` | `var(--primary)` |
| `.active` | `background` | `var(--surface-alt)` |
| `.badge` | `color` | `#fff` |
| `.badge` | `background` | `var(--danger)` |
| `.badge` | `width` | `12px` |
| `.type-chip` | `font-size` | `9px` |
| `.type-chip` | `font-weight` | `500` |
| `.type-chip` | `border-radius` | `12px` |
| `.type-chip` | `padding` | `3px 8px` |
| `.type-chip` | `gap` | `3px` |
| `.type-chip` | `color` | `var(--text-secondary)` |
| `.type-chip` | `background` | `var(--surface-alt)` |
| `.type-chip` | `border` | `1px solid var(--border)` |
| `.dot` | `border-radius` | `50%` |
| `.dot` | `width` | `5px` |
| `.dot` | `height` | `5px` |
| `.date-group` | `font-size` | `10px` |
| `.date-group` | `font-weight` | `600` |
| `.date-group` | `padding` | `8px 12px 2px` |
| `.date-group` | `gap` | `6px` |
| `.date-group` | `color` | `var(--text-secondary)` |
| `.line` | `background` | `var(--border)` |
| `.line` | `height` | `1px` |
| `.cnt` | `font-size` | `9px` |
| `.cnt` | `font-weight` | `500` |
| `.cnt` | `border-radius` | `6px` |
| `.cnt` | `padding` | `1px 5px` |
| `.cnt` | `background` | `var(--surface)` |
| `.cnt` | `border` | `1px solid var(--border)` |
| `.alert-card` | `border-radius` | `10px` |
| `.alert-card` | `background` | `var(--surface-alt)` |
| `.alert-card` | `border` | `1px solid transparent` |
| `.alert-icon` | `font-size` | `14px` |
| `.alert-icon` | `border-radius` | `7px` |
| `.alert-icon` | `width` | `28px` |
| `.alert-icon` | `height` | `28px` |
| `.critical` | `color` | `var(--danger)` |
| `.critical` | `background` | `#FCEAE8` |
| `.estrus` | `color` | `var(--estrus)` |
| `.estrus` | `background` | `#FCEAF2` |
| `.ai` | `color` | `#7C3AED` |
| `.ai` | `background` | `#EDE9FE` |
| `.alert-title` | `font-size` | `11px` |
| `.alert-title` | `font-weight` | `600` |
| `.alert-title` | `height` | `1.3` |
| `.unread-dot` | `border-radius` | `50%` |
| `.unread-dot` | `background` | `var(--primary)` |
| `.unread-dot` | `width` | `6px` |
| `.unread-dot` | `height` | `6px` |
| `.alert-meta` | `font-size` | `9px` |
| `.alert-meta` | `gap` | `4px` |
| `.alert-meta` | `color` | `var(--text-secondary)` |
| `.type-badge` | `font-size` | `8px` |
| `.type-badge` | `font-weight` | `600` |
| `.type-badge` | `border-radius` | `3px` |
| `.type-badge` | `padding` | `1px 5px` |
| `.resolved` | `color` | `var(--success)` |
| `.resolved` | `background` | `#E8F5EC` |
| `.status-tag` | `font-size` | `8px` |
| `.status-tag` | `font-weight` | `600` |
| `.status-tag` | `border-radius` | `3px` |
| `.status-tag` | `padding` | `1px 5px` |
| `.dismissed` | `color` | `var(--text-secondary)` |
| `.dismissed` | `background` | `#E8E8E8` |
| `.auto_resolved` | `color` | `var(--success)` |
| `.auto_resolved` | `background` | `#E8F5EC` |
| `.source-tag` | `font-size` | `7px` |
| `.source-tag` | `font-weight` | `700` |
| `.source-tag` | `border-radius` | `2px` |
| `.source-tag` | `padding` | `0 3px` |
| `.source-tag` | `color` | `#7C3AED` |
| `.source-tag` | `background` | `#F3F0FA` |
| `.rule` | `color` | `var(--primary-dark)` |
| `.rule` | `background` | `#E8F0E5` |
| `.batch-cb` | `border-radius` | `4px` |
| `.batch-cb` | `border` | `2px solid var(--border)` |
| `.batch-cb` | `width` | `18px` |
| `.batch-cb` | `height` | `18px` |
| `.checked` | `color` | `var(--primary)` |
| `.checked` | `background` | `var(--primary)` |
| `.checked::after` | `border` | `solid #fff` |
| `.checked::after` | `width` | `5px` |
| `.checked::after` | `height` | `9px` |
| `.detail-sheet` | `border-radius` | `16px 16px 0 0` |
| `.detail-sheet` | `box-shadow` | `var(--shadow-sheet)` |
| `.detail-sheet` | `background` | `var(--surface-alt)` |
| `.detail-sheet` | `width` | `100%` |
| `.detail-sheet` | `height` | `88%` |
| `.detail-handle` | `border-radius` | `2px` |
| `.detail-handle` | `margin` | `8px auto 0` |
| `.detail-handle` | `background` | `var(--border)` |
| `.detail-handle` | `width` | `32px` |
| `.detail-handle` | `height` | `3px` |
| `.detail-close` | `font-size` | `14px` |
| `.detail-close` | `border-radius` | `50%` |
| `.detail-close` | `color` | `var(--text-secondary)` |
| `.detail-close` | `background` | `var(--surface)` |
| `.detail-close` | `border` | `none` |
| `.detail-close` | `width` | `24px` |
| `.detail-close` | `height` | `24px` |
| `.detail-icon-lg` | `font-size` | `24px` |
| `.detail-icon-lg` | `border-radius` | `14px` |
| `.detail-icon-lg` | `margin` | `0 auto 6px` |
| `.detail-icon-lg` | `width` | `48px` |
| `.detail-icon-lg` | `height` | `48px` |
| `.detail-title` | `font-size` | `13px` |
| `.detail-title` | `font-weight` | `700` |
| `.detail-title` | `height` | `1.3` |
| `.detail-desc` | `font-size` | `11px` |
| `.detail-desc` | `border-radius` | `6px` |
| `.detail-desc` | `padding` | `8px` |
| `.detail-desc` | `background` | `var(--surface)` |
| `.detail-desc` | `height` | `1.5` |
| `.fl` | `font-size` | `9px` |
| `.fl` | `color` | `var(--text-secondary)` |
| `.fv` | `font-size` | `11px` |
| `.fv` | `font-weight` | `600` |
| `.detail-timeline` | `border-radius` | `6px` |
| `.detail-timeline` | `padding` | `8px` |
| `.detail-timeline` | `background` | `var(--surface)` |
| `.detail-timeline-title` | `font-size` | `10px` |
| `.detail-timeline-title` | `font-weight` | `600` |
| `.detail-timeline-item` | `font-size` | `9px` |
| `.detail-timeline-item` | `padding` | `3px 0` |
| `.detail-timeline-item` | `gap` | `8px` |
| `.detail-timeline-item` | `color` | `var(--text-secondary)` |
| `.tl-dot` | `border-radius` | `50%` |
| `.tl-dot` | `width` | `6px` |
| `.tl-dot` | `height` | `6px` |
| `.detail-actions` | `padding` | `10px 14px` |
| `.detail-actions` | `gap` | `5px` |
| `.btn` | `font-size` | `10px` |
| `.btn` | `font-weight` | `600` |
| `.btn` | `border-radius` | `6px` |
| `.btn` | `padding` | `8px 0` |
| `.btn` | `border` | `none` |
| `.btn` | `width` | `50px` |
| `.btn-primary` | `color` | `#fff` |
| `.btn-primary` | `background` | `var(--primary)` |
| `.btn-secondary` | `color` | `var(--primary-dark)` |
| `.btn-secondary` | `background` | `var(--primary-soft)` |
| `.btn-danger` | `color` | `var(--danger)` |
| `.btn-danger` | `background` | `#FCEAE8` |
| `.btn-disabled` | `color` | `var(--text-secondary)` |
| `.btn-disabled` | `background` | `var(--border)` |
| `.btn-nav` | `color` | `#fff` |
| `.btn-nav` | `background` | `var(--info)` |
| `.btn-traj` | `color` | `#7C3AED` |
| `.btn-traj` | `background` | `#EDE9FE` |
| `.empty-icon` | `font-size` | `24px` |
| `.empty-icon` | `border-radius` | `50%` |
| `.empty-icon` | `background` | `var(--primary-soft)` |
| `.empty-icon` | `width` | `56px` |
| `.empty-icon` | `height` | `56px` |
| `.empty-state h3` | `font-size` | `13px` |
| `.empty-state h3` | `font-weight` | `600` |
| `.empty-state p` | `font-size` | `10px` |
| `.empty-state p` | `color` | `var(--text-secondary)` |
| `.empty-state p` | `height` | `1.4` |
| `.bottom-nav` | `padding` | `5px 0 14px` |
| `.bottom-nav` | `background` | `var(--surface-alt)` |
| `.nav-item` | `font-size` | `9px` |
| `.nav-item` | `padding` | `3px` |
| `.nav-item` | `gap` | `2px` |
| `.nav-item` | `color` | `var(--text-secondary)` |
| `.nav-icon` | `font-size` | `18px` |
| `.nav-icon` | `height` | `1` |
| `.ls-health-row` | `padding` | `10px 14px 6px` |
| `.ls-health-row` | `gap` | `8px` |
| `.ls-health-dot` | `border-radius` | `50%` |
| `.ls-health-dot` | `width` | `12px` |
| `.ls-health-dot` | `height` | `12px` |
| `.ls-code` | `font-size` | `15px` |
| `.ls-code` | `font-weight` | `700` |
| `.ls-breed` | `font-size` | `9px` |
| `.ls-breed` | `font-weight` | `600` |
| `.ls-breed` | `border-radius` | `8px` |
| `.ls-breed` | `padding` | `2px 8px` |
| `.ls-breed` | `color` | `var(--primary-dark)` |
| `.ls-breed` | `background` | `var(--primary-soft)` |
| `.ls-alert-banner` | `border-radius` | `8px` |
| `.ls-alert-banner` | `padding` | `8px 10px` |
| `.ls-alert-banner` | `margin` | `6px 14px` |
| `.ls-alert-banner` | `gap` | `8px` |
| `.ls-alert-banner` | `background` | `rgba(194,86,75,.06)` |
| `.ls-alert-banner` | `border` | `1px solid rgba(194,86,75,.2)` |
| `.ls-ab-icon` | `font-size` | `14px` |
| `.ls-ab-icon` | `border-radius` | `7px` |
| `.ls-ab-icon` | `background` | `#FCEAE8` |
| `.ls-ab-icon` | `width` | `28px` |
| `.ls-ab-icon` | `height` | `28px` |
| `.ls-ab-text` | `font-size` | `10px` |
| `.ls-ab-text` | `font-weight` | `600` |
| `.ls-ab-text` | `color` | `var(--danger)` |
| `.ls-ab-text` | `height` | `1.3` |
| `.ls-ab-arrow` | `font-size` | `14px` |
| `.ls-ab-arrow` | `color` | `var(--text-secondary)` |
| `.ls-stats` | `padding` | `6px 14px` |
| `.ls-stats` | `gap` | `6px` |
| `.ls-stat` | `border-radius` | `8px` |
| `.ls-stat` | `padding` | `6px 8px` |
| `.ls-stat` | `background` | `var(--surface)` |
| `.ls-stat-label` | `font-size` | `8px` |
| `.ls-stat-label` | `color` | `var(--text-secondary)` |
| `.ls-stat-value` | `font-size` | `13px` |
| `.ls-stat-value` | `font-weight` | `700` |
| `.ls-stat-unit` | `font-size` | `9px` |
| `.ls-stat-unit` | `font-weight` | `400` |
| `.ls-stat-unit` | `color` | `var(--text-secondary)` |
| `.ls-stat-sub` | `font-size` | `8px` |
| `.ls-stat-sub` | `color` | `var(--text-secondary)` |
| `.ls-actions` | `padding` | `8px 14px` |
| `.ls-actions` | `gap` | `5px` |
| `.ls-related-title` | `font-size` | `10px` |
| `.ls-related-title` | `font-weight` | `600` |
| `.ls-related-title` | `color` | `var(--text-secondary)` |
| `.ls-related-item` | `font-size` | `9px` |
| `.ls-related-item` | `padding` | `4px 0` |
| `.ls-related-item` | `gap` | `6px` |
| `.ls-ri-icon` | `font-size` | `11px` |
| `.ls-ri-icon` | `border-radius` | `5px` |
| `.ls-ri-icon` | `width` | `20px` |
| `.ls-ri-icon` | `height` | `20px` |
| `.notes-panel` | `border-radius` | `12px` |
| `.notes-panel` | `padding` | `20px` |
| `.notes-panel` | `margin` | `32px auto 0` |
| `.notes-panel` | `box-shadow` | `var(--shadow-card)` |
| `.notes-panel` | `background` | `var(--surface-alt)` |
| `.notes-panel` | `width` | `2000px` |
| `.notes-panel h2` | `font-size` | `16px` |
| `.notes-panel h2` | `font-weight` | `700` |
| `.notes-panel h2` | `color` | `var(--primary)` |
| `.notes-panel h3` | `font-size` | `14px` |
| `.notes-panel h3` | `font-weight` | `700` |
| `.notes-panel h3` | `margin` | `20px 0 8px` |
| `.notes-panel h3` | `color` | `var(--info)` |
| `.note-card` | `border-radius` | `8px` |
| `.note-card` | `padding` | `12px` |
| `.note-card` | `background` | `var(--surface)` |
| `.note-title` | `font-size` | `13px` |
| `.note-title` | `font-weight` | `700` |
| `.note-title` | `color` | `var(--primary)` |
| `.note-body` | `font-size` | `11px` |
| `.note-body` | `color` | `var(--text-secondary)` |
| `.note-body` | `height` | `1.5` |
| `.note-body li` | `margin` | `3px 0` |
| `.note-body li` | `gap` | `4px` |
| `.compare-col` | `font-size` | `11px` |
| `.compare-col` | `border-radius` | `8px` |
| `.compare-col` | `padding` | `12px` |
| `.compare-col` | `height` | `1.5` |
| `.before` | `color` | `#7A2E25` |
| `.before` | `background` | `#FCEAE8` |
| `.before` | `border` | `1px solid rgba(194,86,75,.2)` |
| `.after` | `color` | `#2A5A35` |
| `.after` | `background` | `#E8F5EC` |
| `.after` | `border` | `1px solid rgba(76,154,95,.2)` |

## Flutter Implementation Notes (NIX-52)

### Color Gap Analysis

All 14 existing `AppColors` constants match the prototype `:root` exactly.
One new token was added:

| Token | CSS Value | Flutter | Status |
|-------|-----------|---------|--------|
| `--ai-purple` (`.ai`, `.source-tag`, `.btn-traj`) | `#7C3AED` | `AppColors.aiAnomaly = Color(0xFF7C3AED)` | Added |

### Radius Mapping (no new class needed)

The prototype defines `--radius-sm/md/lg` whose numeric values already exist
in `AppSpacing`. Map directly:

| CSS Token | Value | Flutter Equivalent |
|-----------|-------|--------------------|
| `--radius-sm` | `8px` | `BorderRadius.circular(AppSpacing.sm)` |
| `--radius-md` | `12px` | `BorderRadius.circular(AppSpacing.md)` |
| `--radius-lg` | `16px` | `BorderRadius.circular(AppSpacing.lg)` |

### Shadow Constants

Use these literal `List<BoxShadow>` values during coding:

```dart
// --shadow-card
[BoxShadow(offset: Offset(0,1), blurRadius: 3, color: Color.fromRGBO(38,49,38,0.06)),
 BoxShadow(offset: Offset(0,1), blurRadius: 2, color: Color.fromRGBO(38,49,38,0.04))]

// --shadow-elev
[BoxShadow(offset: Offset(0,4), blurRadius: 16, color: Color.fromRGBO(38,49,38,0.12))]

// --shadow-sheet
[BoxShadow(offset: Offset(0,-4), blurRadius: 24, color: Color.fromRGBO(38,49,38,0.15))]
```

### Component Tint Colors (derived from base)

| CSS Class | Background | Flutter |
|-----------|-----------|---------|
| `.critical` / `.btn-danger` / `.ls-ab-icon` | `#FCEAE8` | `AppColors.danger.withValues(alpha: 0.1)` |
| `.estrus` | `#FCEAF2` | `AppColors.estrus.withValues(alpha: 0.1)` |
| `.ai` / `.btn-traj` | `#EDE9FE` | `AppColors.aiAnomaly.withValues(alpha: 0.1)` |
| `.resolved` / `.auto_resolved` | `#E8F5EC` | `AppColors.success.withValues(alpha: 0.1)` |
| `.dismissed` | `#E8E8E8` | `AppColors.textSecondary.withValues(alpha: 0.15)` |
| `.rule` | `#E8F0E5` | `AppColors.primaryDark.withValues(alpha: 0.12)` |
| `.source-tag` | `#F3F0FA` | `AppColors.aiAnomaly.withValues(alpha: 0.06)` |
