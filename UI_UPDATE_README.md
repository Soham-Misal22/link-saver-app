## Link Saver - UI Redesign (Material 3)

What changed
- Implemented design tokens and Material 3 theming.
- Updated Login, Folder Grid, Folder View, Add Link flow visuals, Create Folder modal visuals, and Admin Dashboard polish.

Where to find things
- Tokens: `lib/theme/colors.dart`, `lib/theme/typography.dart`, `lib/theme/shapes.dart`
- Main UI (updated): `lib/main.dart`
- Admin Dashboard (styled in-place): `lib/main.dart` (AdminDashboard class)
- Assets: `assets/icons/*.svg`, `assets/illustrations/*.svg`, `assets/example_data.json`
- pubspec updates (packages + assets): `pubspec.yaml`

Notes
- Navigation, data models, and backend calls are unchanged.
- Uses Inter via `google_fonts`. Icons added as SVG (via `flutter_svg` for future use).

Quick QA checklist
- Colors follow tokens; app bars show gradient; cards use large radius and soft shadows.
- Login: large title and auth block centered in a rounded card.
- Folder Grid: 2-column, rounded folder cards, pill search field, FABs at bottom-right.
- Folder View: link cards with leading icon, domain chip, and date; delete action works.
- Add Link / Create Folder dialogs: rounded surfaces, labels clear, inputs accessible.
- Admin Dashboard: gradient app bar, KPI cards readable, charts visible and responsive.
- Accessibility: minimum tappable area, labeled icons, body text contrast >= 4.5:1.
- Performance: lists scroll smoothly, no heavy blurs; images lazy-loaded by default.

Seed data for previews
- `assets/example_data.json` provides small dataset for design previews (no runtime binding).


