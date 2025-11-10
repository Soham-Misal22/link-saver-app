1 — High level design direction

Design language: Modern, soft, friendly, elevated Material-inspired mobile UI with subtle glass/frosted cards, rounded corners, and large readable type. Follow platform conventions (Android Material 3/Compose) for patterns and motion. 
Android Developers

Tone: warm, helpful, minimal friction. Focus on clarity of content (link title + source + date) and clear actions (save, open, delete). Use pastel gradients as accents, clean white cards with soft shadows for content. For admin screens, use a calmer cool gradient and clear KPI cards. 
Design Studio
+1

Key UX principles to follow: clear information hierarchy, consistent spacing, accessible typography, meaningful micro-interactions for saves/ deletes, clear feedback for async actions. Dashboards should prioritize top KPIs and enable scanability. 
Justinmind |
+1

2 — Deliverables for Cursor (what you must produce)

Figma / Figma Tokens file (or equivalent): full design system (colors, typography, spacing, components). Mark variants & responsive behavior.

Pixel-perfect screens (phone size 360×800 typical and a tablet layout):

Onboarding/Login (social + email)

Main Folder Grid (user) + Search state + Empty state

Folder view (list of saved links) + Empty state

Add Link flow (share sheet dialog + save modal)

Create Folder modal / sheet

Admin Dashboard (cards + charts + list + activity)

Settings/Profile + Sign out

Component library / specs (SVG icons, PNG export sizes, asset folder): cards, list-items, FABs, icon set, chips, text inputs, modal sheets.

Design tokens / CSS variables (colors, radii, shadows, spacing scale). If using Compose, provide token mapping to Material3 theme values.

Interaction spec: micro-interactions (save success animation, delete confirm, FAB open/close, pull-to-refresh, card elevation on press).

Accessibility checklist: contrast ratios, target touch sizes, screen-reader labels.

Handoff notes & acceptance checklist (see Section 12).

3 — Brand & theme (concrete values)

Primary palette (friendly / soft):

Primary gradient: #6EC1FF → #8FD3A3 (blue → mint) for app top bar and hero areas (use gently).

Accent gradient (warm): #FFB49A → #FFD37A for user app background subtle overlay behind content.

Card background: #FFFFFF (cards)

Surface / modal: #F6F7FB (light neutral)

Muted text: #6B7280

Primary text: #111827

Success: #16A34A, Error: #EF4444, Info: #0EA5E9
(These are suggestions — keep consistent token names: --color-primary, --surface, --text-primary, etc.)

Corner radii: large friendly radius for main cards: 20px; smaller card elements: 12px; pill buttons: 999px.

Shadows: soft, multi-layered: 0 6px 18px rgba(15, 23, 42, 0.08) + subtle inner blur for frosted look.

Spacing scale (8pt base): 4, 8, 12, 16, 24, 32, 40, 48 (use tokens).

4 — Typography

Font family: Inter (or Google Sans / Roboto Flex). Use variable weights.

Scale:

H1 / screen title: 28–32sp (bold)

H2 / card title: 18–20sp (600)

Body: 14–16sp (regular)

Caption / meta: 12sp (medium/500, muted color)

Line-height: 1.25–1.4 depending on context for readability.

5 — Iconography & imagery

Use a single system icon set (Material / custom) with 20–24px grid. Provide all icons in SVG.

For folder thumbnails use a soft gradient rounded square with folder icon inside (subtle drop shadow). Use a small site-favicon extraction for link list if possible (fallback to domain chip with soft rounded background).

Provide one or two hero illustrations (vector) for empty states (folder empty, no saves yet).

6 — Component specs (detailed)
6.1 Login / Welcome screen

Layout: top app bar with very light gradient background; centered rounded large card (modal) with social login + or separator + email form. Keep logo small and title large.

Social login buttons: full width, icon + label, 44–56px height, pill radius. Use clear outlines and brand icon on left. Provide disabled and loading states.

Email input: floating label within card; show validation inline. "Forgot password" as tertiary small button. Include an unobtrusive "Sign up" link at bottom.

Motion: subtle card entrance (fade + translateY 12px) and micro bounce on login success. (See login best practices). 
The Interaction Design Foundation

6.2 Folder Grid (main user screen)

Top area: large title “My Saved Folders” left; small profile icon on right. Search field directly under title with pill style and search icon.

Grid: 2 columns on phones (16px gap). Each tile is a card: rounded 16–20px, white, with small folder thumbnail top-left, delete icon top-right, title (bold) and subtitle (light: "Tap to open"). Use consistent inner padding (16px). Card shadows soft.

Empty state: center illustration, CTA “Create your first folder”.

FAB: single primary FAB bottom-right with expand-to-actions (Add Link, Add Folder). Use a speed-dial style: single FAB that expands into two labelled mini-sheets. Keep gestures: tapping elsewhere closes. Use Material FAB guidelines (placement, size, not covering important content). 
Material Design

6.3 Folder view (list of saved links)

List item card: full-width rounded card with left small link icon, title (2-line ellipsis), below show domain chip (rounded pill with light background) and date (muted). Delete icon at right. Card padding 16px.

Interaction: tap card -> open link (safely in external browser). Long-press -> show contextual menu (move to folder, share, delete, copy link).

Sorting/Filters: top right overflow menu for sorting (Newest, Oldest, Source). Provide pull-to-refresh.

6.4 Add Link / Share sheet flow

When user shares from other app, a sheet (bottom modal) appears (full-height optional) with pre-filled URL, preview (fetch title & domain), folder chooser (list with icons), and “Save” CTA. Provide Create New Folder item at bottom. Keep cancel action.

Preview: show favicon (or link icon), title (editable), domain chip, automatic suggestion of folder (recent or suggested).

Microcopy: explain "This app saves only URLs. We don't download content." (privacy reassurance).

6.5 Create Folder modal

Small sheet with folder name input, optional color/tag, and “Create” button. Auto-suggest existing names to avoid duplicates.

6.6 Admin Dashboard (analytics)

Top bar: Admin Dashboard title + logout. Use cool toned gradient background.

KPI cards: stacked vertically, full-width cards with icon left, label small, metric large. Provide quick filters (per day/week/month). Keep cards tappable to open details. Use clear visual hierarchy. 
Justinmind |

Charts section: donut for Popular Folders, horizontal bars for Top Sources, list for Recent Saves, and sparkline/mini bar chart for user activity. Charts inside white rounded container with small legend. Use accessible colors & label values. Use animation on load (radial reveal, bar grow) — subtle and performant. 
Pencil & Paper

7 — Motion & micro-interactions

General: motion should be quick (150–300ms), easing cubic-bezier(.2,.9,.3,1). Use motion to communicate hierarchy, not to distract.

Examples:

Card press: elevate (translateY -2px + shadow increase) for 120ms.

FAB expand: main FAB rotates 45° and two labeled buttons fade/slide out.

Save success: small checkmark pulse on the saved card, and toast that slides in from top for 2.5s.

Delete: swipe-left to reveal delete with haptic and confirm snackbar "Undo".

Accessibility: allow reduced-motion setting respect.

8 — Accessibility & performance

Contrast: text must meet WCAG 2.1 AA (contrast >= 4.5:1 for body text). Provide a high-contrast theme or toggle.

Touch targets: minimum 44×44 dp for interactive items.

Screen-reader: label all icons, provide contentDescription for Android.

Performance: lazy-load images/favicons, avoid heavy shadows/filters on long lists, use RecyclerView/Compose LazyColumn with item recycling. Use progressive loading for charts.

9 — Technical notes (Android dev guidance)

Framework: Jetpack Compose recommended — easier to implement Material3 theming & animations. Use Material3 components (TopAppBar, Card, FAB, ModalBottomSheet). 
Android Developers

Theming: export design tokens to Color.kt, Typography.kt, Shapes.kt. Use Compose MaterialTheme with dynamic colors if desired.

Charts: use a lightweight chart library that supports Compose (or custom Canvas) for donut and bars; animate with Compose animation APIs.

Share sheet integration: implement Android Intent.ACTION_SEND handling and show the designed sheet with pre-filled fields. Detect URLs and sanitize.

Assets: provide SVG icons; use vector drawables or Compose icons to preserve sharpness.

10 — Content & copywriting suggestions (microcopy)

Keep labels short and friendly. Examples:

Empty folder: “No links yet — save something from any app via Share.” CTA: “Save your first link”

Save success toast: “Saved to ‘roo’ ✅” + “Open” action.

Delete undo: “Link deleted” — “Undo”.

Privacy note on login screen: “We save only URLs and captions. We do not store video files.”

11 — Assets to provide to Cursor (exact file list)

Logo (SVG, 3 variants: full color, monochrome, small favicon)

App icon (adaptive Android icon layers)

Folder thumbnail SVG template (rounded square + folder)

All UI icons in SVG (24px grid): search, profile, add, link, delete, copy, share, settings, logout, chart, etc.

Figma tokens export (colors, spacing, type scale, radii, shadows)

Illustrations (empty states) as vector SVG

Example dataset for admin (JSON) to prototype charts and lists (5–10 items). Provide example: {title, url, domain, savedAt, folder}.

12 — Handoff & acceptance criteria (how to verify work)

Must pass:

Implemented color tokens, typography tokens, and spacing token system.

All screens listed in Deliverables present and functional (click prototypes).

Folder grid: 2-column responsive, cards match specs (radii, spacing, icons).

FAB: expands to Add Link & Create Folder with proper animation and accessible labels.

Add Link sheet: pre-fills URL from share intent and allows saving to folder or creating new folder.

Admin dashboard: KPI cards and charts implemented, legends and values labeled.

Accessibility: contrast & touch target requirements met; screen-reader labels exist.

Unit of micro-interactions implemented: save animation + delete undo snackbar.

Optional (nice to have): favicon extraction for links, domain chip colorization, dark mode theme.

13 — Implementation steps (recommended sprint tasks)

Sprint 0 (Design tokens + skeleton): deliver theme tokens and main layout wireframes.

Sprint 1 (Core user flows): Folder Grid, Folder View, FAB, Add Link sheet integration.

Sprint 2 (Admin dashboard + charts): KPI cards, donut, bars, lists.

Sprint 3 (Polish & accessibility): microinteractions, animations, accessibility fixes, QA.

Sprint 4 (Handoff & final assets): finalize Figma, export assets, document components.

Note: these sprints are guidelines — adjust to your team size.

14 — Example component spec (copyable tokens & CSS-like mapping)

--radius-lg: 20px

--radius-md: 12px

--shadow-1: 0 6px 18px rgba(15, 23, 42, 0.08)

--primary-gradient: linear-gradient(135deg,#6EC1FF,#8FD3A3)

--surface: #FFFFFF

--muted: #6B7280

Typography: --h1: 28px/36px 700, --body: 16px/24px 400, --caption: 12px/18px 500.

(Provide mapping to Compose theme in Color.kt, Typography.kt.)

15 — Accessibility checklist (deliverable)

All interactive elements have contentDescription and keyboard focus order.

Text contrast >= 4.5:1 (body) and >= 3:1 for large text.

Touchable area >= 44 × 44 dp.

Reduced–motion toggle respected.

Test with TalkBack and common screen sizes.

16 — Suggested visual examples & references (for inspiration)

Clean modern login flows (Interaction Design examples). 
The Interaction Design Foundation

Material 3 floating action button guidelines (for FAB behavior & placement). 
Material Design

Dashboard & analytics best practices (Justinmind / Pencil & Paper dashboard guidance). 
Justinmind |
+1

2025 mobile UI trends (microinteractions, personalization, minimal interfaces). 
Design Studio

17 — Examples of specific changes from your current screens (mapping)

Current login card → New: more breathing room, larger title, social buttons with brand icons, clearer email input, reduced inner shadows, stronger contrast on CTAs. 
The Interaction Design Foundation

Folder grid cards → New: increase corner radius to 16–20px, add consistent inner padding, subtle drop shadows, domain/folder color thumbnails, hover/press elevation.

Add Link share sheet → New: full-featured sheet that previews URL & suggests folders, editable title, Create Folder inline.

Admin dashboard → New: KPI-first layout, consistent card sizes, readable legends, animated chart entrances, easier filter controls. 
Justinmind |

18 — Acceptance checklist for each delivered screen (developer QA)

Pixel-check against Figma (±2px on spacing).

All icons SVG and exported at x1/x2/x3.

All interactive elements accessible and labeled.

Animations smooth on mid-range devices (test on low-end too).

Share sheet correctly handles Intent.ACTION_SEND and pre-fills the URL and title.

19 — Final notes (project risks & suggestions)

Risk: heavy visual effects (blurred glass) can hurt performance on low-end devices — prefer light blur or simulated frosted background using semi-opaque surfaces and no heavy GPU filters.

Suggestion: keep a single source-of-truth for tokens (one JSON / tokens file) so design and dev use same values. Consider shipping a small design system library as Compose components to accelerate dev. 
Android Developers

20 — Quick start checklist to hand to designers/devs (one-page)

Get Figma file + tokens.

Export SVG icon set + adaptive app icon.

Implement Material3 theme with color tokens. 
Android Developers

Build Folder Grid + Folder view + Add Link sheet. Integrate share intent.

Add FAB speed-dial (Add Link / Create Folder) per guidelines. 
Material Design

Build Admin dashboard (KPI cards + charts). Use example JSON to seed charts. 
Justinmind |

QA for accessibility & device performance.