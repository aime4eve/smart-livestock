# Design Tokens (extracted from prototype)

Source: `docs/marketing/gps-quality-rtk-truth-points-browse-prototype.html`

## CSS Custom Properties (:root)

| Token | CSS Value | Category | Flutter Equivalent |
|-------|-----------|----------|-------------------|
| `--color-border` | `#D7D2C6` | Color | `Color(0xFFD7D2C6)` |
| `--color-danger` | `#C2564B` | Color | `Color(0xFFC2564B)` |
| `--color-danger-soft` | `#FBE8E6` | Color | `Color(0xFFFBE8E6)` |
| `--color-primary` | `#2F6B3B` | Color | `Color(0xFF2F6B3B)` |
| `--color-primary-dark` | `#244F2D` | Color | `Color(0xFF244F2D)` |
| `--color-primary-soft` | `#E3F0E4` | Color | `Color(0xFFE3F0E4)` |
| `--color-row-hover` | `#FBFAF6` | Color | `Color(0xFFFBFAF6)` |
| `--color-surface` | `#F8F6F0` | Color | `Color(0xFFF8F6F0)` |
| `--color-surface-alt` | `#FFFFFF` | Color | `Color(0xFFFFFFFF)` |
| `--color-surface-muted` | `#F2F0EA` | Color | `Color(0xFFF2F0EA)` |
| `--color-text` | `#263126` | Color | `Color(0xFF263126)` |
| `--color-text-secondary` | `#617061` | Color | `Color(0xFF617061)` |
| `--font-mono` | `ui-monospace, SFMono-Regular, Menlo, Consolas, monospace` | Other | `ui-monospace, SFMono-Regular, Menlo, Consolas, monospace` |
| `--radius-lg` | `8px` | Spacing | `8` |
| `--radius-md` | `6px` | Spacing | `6` |
| `--radius-sm` | `4px` | Spacing | `4` |
| `--shadow-card` | `0 1px 2px rgba(38, 49, 38, 0.08)` | Color | `0 1px 2px rgba(38, 49, 38, 0.08)` |
| `--space-lg` | `16px` | Spacing | `16` |
| `--space-md` | `12px` | Spacing | `12` |
| `--space-sm` | `8px` | Spacing | `8` |
| `--space-xl` | `24px` | Spacing | `24` |
| `--space-xs` | `4px` | Spacing | `4` |

## Component-Level Styles (key selectors)

| Selector | Property | Value |
|----------|----------|-------|
| `.top-bar` | `padding` | `0 var(--space-xl)` |
| `.top-bar` | `gap` | `var(--space-md)` |
| `.top-bar` | `background` | `var(--color-surface-alt)` |
| `.top-bar` | `height` | `56px` |
| `.top-bar h1` | `font-size` | `15px` |
| `.top-bar h1` | `font-weight` | `600` |
| `.top-bar h1` | `margin` | `0` |
| `.context` | `font-size` | `13px` |
| `.context` | `color` | `var(--color-text-secondary)` |
| `.icon-button` | `border-radius` | `var(--radius-md)` |
| `.icon-button` | `color` | `var(--color-text-secondary)` |
| `.icon-button` | `background` | `transparent` |
| `.icon-button` | `border` | `0` |
| `.icon-button` | `width` | `34px` |
| `.icon-button` | `height` | `34px` |
| `.icon-button:hover` | `color` | `var(--color-text)` |
| `.icon-button:hover` | `background` | `var(--color-surface-muted)` |
| `.main-tabs` | `padding` | `0 var(--space-xl)` |
| `.main-tabs` | `gap` | `var(--space-lg)` |
| `.main-tabs` | `background` | `var(--color-surface-alt)` |
| `.main-tab` | `font-size` | `14px` |
| `.main-tab` | `padding` | `12px 2px` |
| `.main-tab` | `color` | `var(--color-text-secondary)` |
| `.main-tab` | `background` | `transparent` |
| `.main-tab` | `border` | `0` |
| `.active` | `font-weight` | `600` |
| `.active` | `color` | `var(--color-primary)` |
| `.page` | `padding` | `var(--space-xl)` |
| `.page` | `margin` | `0 auto` |
| `.page` | `width` | `min(1280px, 100%)` |
| `.sub-tabs` | `border-radius` | `var(--radius-lg)` |
| `.sub-tabs` | `padding` | `3px` |
| `.sub-tabs` | `background` | `var(--color-surface-alt)` |
| `.sub-tabs` | `border` | `1px solid var(--color-border)` |
| `.sub-tab` | `font-size` | `12px` |
| `.sub-tab` | `border-radius` | `var(--radius-md)` |
| `.sub-tab` | `padding` | `5px 12px` |
| `.sub-tab` | `color` | `var(--color-text-secondary)` |
| `.sub-tab` | `background` | `transparent` |
| `.sub-tab` | `border` | `0` |
| `.sub-tab` | `height` | `32px` |
| `.active` | `background` | `var(--color-primary)` |
| `.rtk-panel` | `border-radius` | `var(--radius-lg)` |
| `.rtk-panel` | `box-shadow` | `var(--shadow-card)` |
| `.rtk-panel` | `background` | `var(--color-surface-alt)` |
| `.rtk-panel` | `border` | `1px solid var(--color-border)` |
| `.rtk-panel` | `height` | `calc(100vh - 160px)` |
| `.panel-header` | `padding` | `var(--space-md) var(--space-lg)` |
| `.panel-header` | `gap` | `var(--space-md)` |
| `.panel-title` | `gap` | `var(--space-sm)` |
| `.panel-title` | `width` | `150px` |
| `.panel-title h2` | `font-size` | `15px` |
| `.panel-title h2` | `font-weight` | `600` |
| `.panel-title h2` | `margin` | `0` |
| `.result-count` | `font-size` | `12px` |
| `.result-count` | `font-weight` | `600` |
| `.result-count` | `border-radius` | `999px` |
| `.result-count` | `padding` | `1px 8px` |
| `.result-count` | `color` | `var(--color-primary)` |
| `.result-count` | `background` | `var(--color-primary-soft)` |
| `.result-count` | `width` | `38px` |
| `.search-field::before` | `border-radius` | `50%` |
| `.search-field::before` | `border` | `2px solid var(--color-text-secondary)` |
| `.search-field::before` | `width` | `12px` |
| `.search-field::before` | `height` | `12px` |
| `.search-field::after` | `border-radius` | `1px` |
| `.search-field::after` | `background` | `var(--color-text-secondary)` |
| `.search-field::after` | `width` | `7px` |
| `.search-field::after` | `height` | `2px` |
| `.search-input` | `font-size` | `13px` |
| `.search-input` | `border-radius` | `var(--radius-md)` |
| `.search-input` | `padding` | `0 12px 0 32px` |
| `.search-input` | `color` | `var(--color-text)` |
| `.search-input` | `background` | `var(--color-surface-alt)` |
| `.search-input` | `border` | `1px solid var(--color-border)` |
| `.search-input` | `width` | `100%` |
| `.search-input` | `height` | `34px` |
| `.search-input:focus` | `box-shadow` | `0 0 0 3px var(--color-primary-soft)` |
| `.search-input:focus` | `color` | `var(--color-primary)` |
| `.primary-button` | `font-size` | `13px` |
| `.primary-button` | `font-weight` | `600` |
| `.primary-button` | `border-radius` | `var(--radius-md)` |
| `.primary-button` | `padding` | `0 12px` |
| `.primary-button` | `gap` | `5px` |
| `.primary-button` | `color` | `#fff` |
| `.primary-button` | `background` | `var(--color-primary)` |
| `.primary-button` | `border` | `0` |
| `.primary-button` | `height` | `34px` |
| `.location-option` | `font-size` | `13px` |
| `.location-option` | `border-radius` | `var(--radius-md)` |
| `.location-option` | `padding` | `6px 10px` |
| `.location-option` | `gap` | `var(--space-sm)` |
| `.location-option` | `color` | `var(--color-text)` |
| `.location-option` | `background` | `transparent` |
| `.location-option` | `border` | `0` |
| `.location-option` | `width` | `100%` |
| `.location-option` | `height` | `36px` |
| `.location-count` | `font-size` | `12px` |
| `.location-count` | `color` | `var(--color-text-secondary)` |
| `.table-panel` | `width` | `0` |
| `.table-panel` | `height` | `calc(100vh - 212px)` |
| `.rtk-table th` | `padding` | `0` |
| `.rtk-table th` | `background` | `var(--color-surface-alt)` |
| `.th-button` | `font-size` | `12px` |
| `.th-button` | `font-weight` | `600` |
| `.th-button` | `padding` | `0 16px` |
| `.th-button` | `gap` | `4px` |
| `.th-button` | `color` | `var(--color-text-secondary)` |
| `.th-button` | `background` | `transparent` |
| `.th-button` | `border` | `0` |
| `.th-button` | `width` | `100%` |
| `.th-button` | `height` | `40px` |
| `.th-button:hover` | `color` | `var(--color-text)` |
| `.th-button:hover` | `background` | `var(--color-surface-muted)` |
| `.rtk-table td` | `font-size` | `13px` |
| `.rtk-table td` | `padding` | `0 16px` |
| `.rtk-table td` | `height` | `40px` |
| `.point-cell` | `font-weight` | `600` |
| `.point-cell` | `width` | `96px` |
| `.location-cell` | `color` | `var(--color-text-secondary)` |
| `.location-cell` | `width` | `180px` |
| `.coordinate` | `font-size` | `12px` |
| `.coordinate` | `width` | `124px` |
| `.delete-button` | `border-radius` | `var(--radius-md)` |
| `.delete-button` | `color` | `var(--color-text-secondary)` |
| `.delete-button` | `background` | `transparent` |
| `.delete-button` | `border` | `0` |
| `.delete-button` | `width` | `28px` |
| `.delete-button` | `height` | `28px` |
| `.delete-button:hover` | `color` | `var(--color-danger)` |
| `.delete-button:hover` | `background` | `var(--color-danger-soft)` |
| `.empty-state` | `font-size` | `13px` |
| `.empty-state` | `padding` | `var(--space-xl)` |
| `.empty-state` | `color` | `var(--color-text-secondary)` |
| `.modal-overlay` | `padding` | `var(--space-lg)` |
| `.modal-overlay` | `background` | `rgba(38, 49, 38, 0.32)` |
| `.modal` | `border-radius` | `var(--radius-lg)` |
| `.modal` | `box-shadow` | `0 16px 48px rgba(38, 49, 38, 0.2)` |
| `.modal` | `background` | `var(--color-surface-alt)` |
| `.modal` | `width` | `min(440px, 100%)` |
| `.modal-header h3` | `font-size` | `15px` |
| `.modal-header h3` | `margin` | `0` |
| `.modal-form` | `padding` | `var(--space-lg)` |
| `.modal-form` | `gap` | `var(--space-md)` |
| `.field-label` | `font-size` | `12px` |
| `.field-label` | `font-weight` | `600` |
| `.field-label` | `color` | `var(--color-text-secondary)` |
| `.text-input` | `font-size` | `13px` |
| `.text-input` | `border-radius` | `var(--radius-md)` |
| `.text-input` | `padding` | `0 10px` |
| `.text-input` | `color` | `var(--color-text)` |
| `.text-input` | `background` | `var(--color-surface-alt)` |
| `.text-input` | `border` | `1px solid var(--color-border)` |
| `.text-input` | `width` | `100%` |
| `.text-input` | `height` | `36px` |
| `.text-input:focus` | `box-shadow` | `0 0 0 3px var(--color-primary-soft)` |
| `.text-input:focus` | `color` | `var(--color-primary)` |
| `.modal-actions` | `padding` | `var(--space-md) var(--space-lg)` |
| `.modal-actions` | `gap` | `var(--space-sm)` |
| `.secondary-button` | `font-size` | `13px` |
| `.secondary-button` | `border-radius` | `var(--radius-md)` |
| `.secondary-button` | `padding` | `0 12px` |
| `.secondary-button` | `color` | `var(--color-text)` |
| `.secondary-button` | `background` | `var(--color-surface-alt)` |
| `.secondary-button` | `border` | `1px solid var(--color-border)` |
| `.secondary-button` | `height` | `34px` |
| `.form-error` | `font-size` | `12px` |
| `.form-error` | `margin` | `0` |
| `.form-error` | `color` | `var(--color-danger)` |
| `.location-nav` | `padding` | `var(--space-sm) var(--space-md)` |
| `.location-nav` | `gap` | `var(--space-sm)` |
