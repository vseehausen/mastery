# Mastery Design Tokens v2.1

**Design System**: Zinc palette + Indigo accent (shadcn/ui compatible)
**Mobile Framework**: Flutter 3.10.7+ with shadcn_ui
**Web Framework**: Tailwind CSS + Iconify

---

## Colors

### Surfaces
```css
--background-light: #FFFFFF;
--background-dark: #09090B;
--foreground-light: #09090B;
--foreground-dark: #FAFAFA;
--card-light: #FFFFFF;
--card-dark: #18181B;
--card-foreground-light: #09090B;
--card-foreground-dark: #FAFAFA;
--popover-light: #FFFFFF;
--popover-dark: #18181B;
--popover-foreground-light: #09090B;
--popover-foreground-dark: #FAFAFA;
```

### Actions
```css
--primary-light: #09090B;
--primary-dark: #FAFAFA;
--primary-foreground-light: #FFFFFF;
--primary-foreground-dark: #09090B;
--secondary-light: #F4F4F5;
--secondary-dark: #27272A;
--secondary-foreground-light: #09090B;
--secondary-foreground-dark: #FAFAFA;
--accent-light: #4F46E5;
--accent-dark: #6366F1;
--accent-foreground-light: #FFFFFF;
--accent-foreground-dark: #FFFFFF;
--destructive-light: #DC2626;
--destructive-dark: #F87171;
--destructive-foreground-light: #FFFFFF;
--destructive-foreground-dark: #FEF2F2;
```

### Neutral
```css
--muted-light: #F4F4F5;
--muted-dark: #27272A;
--muted-foreground-light: #71717A;
--muted-foreground-dark: #A1A1AA;
```

### Form
```css
--border-light: #E4E4E7;
--border-dark: #27272A;
--input-light: #FFFFFF;
--input-dark: #27272A;
--ring-light: #09090B;
--ring-dark: #A1A1AA;
--selection-light: #C7D2FE;
--selection-dark: #3730A3;
```

### Semantic States
```css
--success-light: #10B981;
--success-dark: #059669;
--success-foreground-light: #FFFFFF;
--success-foreground-dark: #FFFFFF;
--success-muted-light: #ECFDF5;
--success-muted-dark: #064E3B;
--warning-light: #F59E0B;
--warning-dark: #D97706;
--warning-foreground-light: #000000;
--warning-foreground-dark: #FFFFFF;
--warning-muted-light: #FFFBEB;
--warning-muted-dark: #451A03;
--info-light: #3B82F6;
--info-dark: #60A5FA;
--info-foreground-light: #FFFFFF;
--info-foreground-dark: #172554;
```

### Domain Cue Colors
```css
--cue-synonym-light: #EEF2FF;
--cue-synonym-dark: #4338CA;
--cue-multiple-choice-light: #F0F9FF;
--cue-multiple-choice-dark: #0369A1;
```

## Typography

### Font Family
```css
--font-family-sans: Plus Jakarta Sans;
--font-family-mono: JetBrains Mono;
```

### Font Size
```css
--font-size-xs: 11px;
--font-size-sm: 14px;
--font-size-base: 16px;
--font-size-lg: 18px;
--font-size-xl: 24px;
--font-size-2xl: 28px;
```

### Font Weight
```css
--font-weight-normal: 400;
--font-weight-medium: 500;
--font-weight-semibold: 600;
--font-weight-bold: 700;
```

### Line Height
```css
--line-height-tight: 1.2;
--line-height-snug: 1.3;
--line-height-normal: 1.4;
--line-height-relaxed: 1.5;
```

### Letter Spacing
```css
--letter-spacing-tight: -0.025em;
--letter-spacing-normal: 0em;
--letter-spacing-wide: 0.025em;
```

## Spacing

### Border Radius
```css
--radius-none: 0px;
--radius-sm: 6px;
--radius-md: 8px;
--radius-lg: 12px;
--radius-xl: 16px;
--radius-2xl: 24px;
--radius-full: 9999px;
```

### Border Width
```css
--border-width-none: 0px;
--border-width-thin: 1px;
--border-width-medium: 2px;
--border-width-thick: 4px;
```

## Shadows

### Light Mode
```css
--shadow-xs-light: 0 1px 2px rgba(0,0,0,0.05);
--shadow-sm-light: 0 1px 3px rgba(0,0,0,0.1), 0 1px 2px rgba(0,0,0,0.06);
--shadow-md-light: 0 4px 6px rgba(0,0,0,0.07), 0 2px 4px rgba(0,0,0,0.06);
--shadow-lg-light: 0 10px 15px rgba(0,0,0,0.1), 0 4px 6px rgba(0,0,0,0.05);
--shadow-xl-light: 0 20px 25px rgba(0,0,0,0.1), 0 10px 10px rgba(0,0,0,0.04);
--shadow-2xl-light: 0 25px 50px rgba(0,0,0,0.15);
```

### Dark Mode
```css
--shadow-xs-dark: 0 1px 2px rgba(0,0,0,0.3);
--shadow-sm-dark: 0 1px 3px rgba(0,0,0,0.4), 0 1px 2px rgba(0,0,0,0.3);
--shadow-md-dark: 0 4px 6px rgba(0,0,0,0.4), 0 2px 4px rgba(0,0,0,0.3);
--shadow-lg-dark: 0 10px 15px rgba(0,0,0,0.5), 0 4px 6px rgba(0,0,0,0.4);
--shadow-xl-dark: 0 20px 25px rgba(0,0,0,0.5), 0 10px 10px rgba(0,0,0,0.4);
```

## Animation

### Duration
```css
--duration-75: 75ms;
--duration-100: 100ms;
--duration-150: 150ms;
--duration-200: 200ms;
--duration-300: 300ms;
--duration-500: 500ms;
--duration-700: 700ms;
```

### Easing
```css
--ease-linear: linear;
--ease-in: cubic-bezier(0.4, 0.0, 1.0, 1.0);
--ease-out: cubic-bezier(0.0, 0.0, 0.2, 1.0);
--ease-in-out: cubic-bezier(0.4, 0.0, 0.2, 1.0);
```

## Z-Index

```css
--z-base: 0;
--z-dropdown: 1000;
--z-sticky: 1100;
--z-fixed: 1200;
--z-modal-backdrop: 1300;
--z-modal: 1400;
--z-popover: 1500;
--z-toast: 1600;
--z-tooltip: 1700;
```

## Icons

### Mobile (Flutter)
```css
--icon-library: Material Icons (cupertino_icons ^1.0.8)
--icon-default-size: 24px
```

**Common Icons**:
- `Icons.error_outline` - Error states
- `Icons.refresh` - Retry actions
- `Icons.inbox_outlined` - Empty states
- `Icons.auto_awesome` - AI/enrichment features
- `Icons.chevron_right` - Navigation
- `Icons.check_circle` - Success states
- `Icons.arrow_back` - Back navigation

### Web/Design
```css
--icon-library: Iconify
--icon-provider: solar (Solar Icon Set)
```

**Common Icons**:
- `solar:book-bookmark-linear` - Logo/branding
- `solar:palette-linear` - Color section
- `solar:text-square-linear` - Typography section
- `solar:smartphone-linear` - Component showcase
- `solar:arrow-left-linear` - Back navigation
- `solar:menu-dots-bold` - More options
- `solar:volume-loud-bold` - Audio playback
- `solar:check-circle-bold` - Success/completion
- `solar:card-linear` - Payment/card
- `solar:wallet-linear` - Wallet
- `solar:add-circle-linear` - Add actions
- `solar:shield-warning-bold` - Warning states
- `solar:close-circle-bold` - Error/close
- `solar:alt-arrow-down-linear` - Dropdown indicators

## Spacing Scale

### Standard Scale (for padding, margin, gap)
```css
--space-0: 0px;
--space-1: 4px;
--space-2: 8px;
--space-3: 12px;
--space-4: 16px;
--space-5: 20px;
--space-6: 24px;
--space-8: 32px;
--space-10: 40px;
--space-12: 48px;
--space-16: 64px;
--space-20: 80px;
--space-24: 96px;
```

## Layout

### Container Max Width
```css
--container-max-width: 1280px (7xl);
```

### Breakpoints
```css
--breakpoint-sm: 640px;
--breakpoint-md: 768px;
--breakpoint-lg: 1024px;
--breakpoint-xl: 1280px;
--breakpoint-2xl: 1536px;
```

## Application Constants

### Learning System
```css
--daily-time-target: 5 minutes;
--target-retention: 0.90 (90%);
--intensity-default: 1;
--native-language: de (German);
--meaning-display-mode: both;
```

## Component Specifications

### Cards
```css
--card-padding: 24px;
--card-radius: 12px;
--card-shadow: var(--shadow-sm-light);
--card-border: 1px solid var(--border-light);
```

### Buttons
```css
--button-height-sm: 36px;
--button-height-md: 44px;
--button-height-lg: 48px;
--button-padding-x: 16px;
--button-radius: 8px;
--button-font-weight: 500;
```

### Inputs
```css
--input-height: 44px;
--input-padding-x: 12px;
--input-radius: 8px;
--input-border-width: 1px;
--input-font-size: 16px;
```

### Navigation
```css
--nav-height: 56px;
--bottom-nav-height: 64px;
--tab-bar-height: 48px;
```
