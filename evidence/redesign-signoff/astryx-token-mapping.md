# Astryx Neutral → Kbo Token Mapping (G004)

Reference source: `node_modules/@astryxdesign/theme-neutral/src/neutralTheme.ts` from the main checkout, used as dev-time reference only. No astryx/React import is added to Swift targets.

## Semantic mapping

| Astryx neutral semantic | Reference values / intent | Kbo SwiftUI mapping |
|-------------------------|---------------------------|---------------------|
| Background body | light `#f1f1f1`, dark `#1b1b1b` | `KboColorToken.backgroundPrimary`, `appBackgroundPrimary` |
| Surface/card | light `#ffffff`, dark `#1b1b1b` | `KboColorToken.surfaceCard`, `KboSurfaceToken.card` |
| Elevated/interactive surface | light `#ffffff`, dark `#262626` | `KboColorToken.surfaceElevated`, `KboSurfaceToken.elevated`, glass control/navigation opaque surfaces |
| Border | light `#ebebeb`, dark `#FFFFFF1A` alpha wash, emphasized `#d4d4d4` / `#525252` | `KboColorToken.borderMuted`, `borderEmphasized`, `KboSurfaceToken.glassBorder` |
| Text primary | light `#171717`, dark `#fafafa` | `KboColorToken.textPrimary` |
| Text secondary | light `#737373`, dark `#a3a3a3` | `KboColorToken.textSecondary` |
| Text disabled/muted | light `#a3a3a3`, dark `#525252` reference; dark adjusted to `#737373` for BaseballLiveKR readability | `KboColorToken.textMuted` |
| Accent neutral | light `#262626`, dark `#ebebeb` | `KboColorToken.accentNeutral`, `KboSemanticColorToken.accentNeutral` |
| Blue | light `#00458c`, dark `#a0caff` | `KboColorToken.accentBlue`, scheduled status |
| Teal | light `#005348`, dark `#83dac9` | `KboColorToken.accentTeal`, mint semantic accent |
| Live/error | light `#a50c25`, dark `#ffc6c1` | `KboColorToken.statusLive`, `danger`, `accentRed` |
| Warning/delayed | light `#745b00`, dark `#fdcf4f` | `KboColorToken.statusDelayed`, `warning` |
| Success | light `#007004`, dark `#9fe59b` | `KboColorToken.success` |
| Typography | base 14, ratio 1.2, bold h3/h4 | `KboTypographyToken.body` now 14 pt, headline bold, score sizes aligned to the same scale while retaining baseball score hierarchy |
| Motion | fast 125 ms, medium 300 ms, slow 700 ms | `KboMotionToken.fastFeedback` 0.125 s, `sectionReveal` 0.30 s; score/live motion remains SwiftUI-native |
| Spacing rhythm | neutral/shadcn-style 4 pt grid | `KboSpacingToken` stays 4/8/12/16 and expands upper stops to 24/32 for clearer section rhythm |
| Radius scale | flatter neutral surface shape | `KboRadiusToken` tightens small/medium/large to 6/10/14 and adds `xLarge` 20 for large panels |
| Elevation | shadows low and neutral | `KboShadowToken` glow reduced; `KboGlassPanel` remains opaque + border from G003 for visible performance |

## Guardrails

- SwiftUI adaptive color providers remain native (`NSColor` / `UIColor`) and preserve light/dark behavior.
- `borderMuted` keeps the light border opaque and applies alpha only in dark mode, matching the neutral reference instead of dimming both appearances.
- Token mapping is semantic, not literal React/CSS shipment.
- No package manifest, Xcode target, or Swift source imports `@astryxdesign`.
- G005 component redesign must consume these Kbo tokens rather than introducing component-local hex values.
