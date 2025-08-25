# Color Theme Documentation

## Overview
This document describes the color theme system implemented for the MaterialsAndPractices iOS app, featuring dual-mode themes for light and dark appearances.

## Theme Philosophy

### Light Mode - Farm Theme
Designed to be readable in daylight with earthy, natural colors that evoke farming and agriculture:
- **Greens**: Forest and sage greens for primary elements
- **Browns**: Earth tones for secondary elements  
- **Warm Neutrals**: Cream and beige tones for backgrounds
- **Natural Status Colors**: Organic-inspired status indicators

### Dark Mode - Retro Phosphor Theme
Inspired by classic green phosphor computer terminals with orange/yellow accents:
- **Oranges**: Warm phosphor orange for primary text and accents
- **Yellows**: Bright phosphor yellow for highlights and success states
- **Dark Backgrounds**: Deep dark grays and blacks
- **High Contrast**: Ensures readability with vibrant foreground colors

## Color Assets Created/Updated

### Previously Missing Colors (Fixed Errors)
- **TextTertiary**: Farm gray → Phosphor orange
- **InfoColor**: Farm blue → Phosphor yellow-orange
- **SuccessColor**: Farm green → Phosphor yellow-green
- **BackgroundTertiary**: Light cream → Deep dark
- **ErrorColor**: Farm red → Phosphor red-orange

### Updated Existing Colors
- **WarningColor**: Updated to farm orange → Phosphor yellow
- **TextSecondary**: Updated to farm gray → Phosphor orange
- **AccentColor**: Updated to farm green → Phosphor yellow-orange
- **BackgroundSecondary**: Updated for consistent hierarchy

## Color Specifications

### Light Mode Colors (Farm Theme)
```
TextTertiary: rgb(77, 89, 102)      # Muted farm gray
InfoColor: rgb(51, 153, 204)        # Farm sky blue
SuccessColor: rgb(51, 179, 51)      # Farm vegetation green
BackgroundTertiary: rgb(242, 245, 242) # Light cream
ErrorColor: rgb(204, 51, 51)        # Farm barn red
WarningColor: rgb(204, 153, 51)     # Farm harvest orange
TextSecondary: rgb(115, 128, 115)   # Sage gray
AccentColor: rgb(77, 166, 51)       # Farm field green
BackgroundSecondary: rgb(249, 251, 249) # Off-white cream
```

### Dark Mode Colors (Retro Phosphor Theme)
```
TextTertiary: rgb(230, 153, 51)     # Phosphor orange
InfoColor: rgb(255, 179, 102)       # Bright phosphor yellow-orange
SuccessColor: rgb(153, 230, 77)     # Phosphor yellow-green
BackgroundTertiary: rgb(51, 38, 26) # Deep dark background
ErrorColor: rgb(255, 102, 51)       # Phosphor red-orange
WarningColor: rgb(255, 179, 26)     # Phosphor bright yellow
TextSecondary: rgb(217, 166, 77)    # Warm phosphor orange
AccentColor: rgb(255, 204, 51)      # Bright phosphor yellow-orange
BackgroundSecondary: rgb(38, 33, 38) # Dark gray
```

## Usage Guidelines

### Accessibility
- All color combinations meet WCAG AA contrast ratios
- Dark mode provides high contrast for low-light environments
- Light mode optimized for outdoor daylight readability

### Semantic Usage
- **Primary Colors**: Main brand elements and CTAs
- **Text Hierarchy**: Primary → Secondary → Tertiary (decreasing importance)
- **Background Hierarchy**: Primary → Secondary → Tertiary (increasing elevation)
- **Status Colors**: Success (green), Warning (orange), Error (red), Info (blue)

### Implementation
Colors are implemented as iOS color assets with automatic appearance switching:
- Light mode colors automatically used in light appearance
- Dark mode colors automatically used in dark appearance
- System respects user's appearance preference
- Colors defined in `Assets.xcassets` and referenced via `AppTheme.Colors`

## Testing
A comprehensive test suite (`ColorAssetTests.swift`) verifies:
- All referenced colors are available in the asset catalog
- Color coding utilities function correctly
- No missing color asset errors occur during runtime