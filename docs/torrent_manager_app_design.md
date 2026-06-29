# Torrent Manager App Design

## Product Positioning

This app is an iOS-style remote console for qBittorrent and Transmission. It should feel like a quiet control room: fast scanning, dense but calm data, predictable destructive actions, and clear support for long-running management work.

The requested "coputinuo" direction is interpreted as Cupertino style: translucent bars, grouped surfaces, large-title navigation, bottom action sheets, contextual menus, and reserved use of color.

## Navigation Model

- **Torrents**: default screen, optimized for filtering, sorting, batch actions, and quick add.
- **RSS**: qBittorrent-only subscription center for feed add, refresh, rename, delete, read state, and article detail.
- **Downloader**: connection profile, version, speed limits, categories, tags, preferences, and logs.
- **Task Detail**: bottom sheet for per-torrent files, trackers, peers, limits, rename, location, tags, category, pause/resume, recheck, and delete.

On mobile, these areas should be reached from the torrent page through top navigation actions and Cupertino bottom sheets, not a heavy permanent drawer. On tablet/desktop width, a two-pane layout can pin the torrent list on the left and detail/RSS/profile content on the right.

## Visual System

### Tone

- Precise, minimal, slightly glassy.
- Data-dense, but with enough vertical rhythm to prevent panic-scanning.
- Text-first UI: icons help recognition, but labels remain clear for destructive and long-running actions.

### Palette

- **Ink** `#171717`: titles and key labels.
- **Canvas** `#F5F5F7`: app background.
- **Surface** `#FFFFFF`: grouped panels and rows.
- **Primary Blue** `#0A84FF`: active filters, download progress, primary actions.
- **Signal Teal** `#30B0C7`: upload, connection, secondary metrics.
- **Ratio Gold** `#D4AF37`: ratio, seeding health, premium/important hints.
- **Danger Red** `#FF453A`: delete, errors, destructive confirmations.

Dark mode should use `#101014` background and `#1C1C1E` grouped surfaces, with the same blue/teal/gold accents softened by lower opacity fills.

### Typography

Use the platform default font. In Flutter, avoid setting a custom font family so iOS keeps San Francisco and Android keeps Roboto. Keep letter spacing at `0`.

- Screen title: 28-34, weight 700.
- Section title: 15-17, weight 700.
- Torrent title: 14-16, weight 700, one line by default.
- Metadata: 11-13, weight 500-600.
- Button label: 13-15, weight 600.

## Core Screens

### Torrents

The torrent page is the operational cockpit.

- Top app bar: downloader name, connection status dot, RSS/log/profile actions.
- Collapsible status strip: total down/up, disk capacity, peer count, queue size, error state.
- Floating bottom toolbar:
  - Filter icon for qBittorrent.
  - Search field for title/category/tag.
  - Sort button with direction.
  - Add button as a filled circular action.
- Torrent rows:
  - Title, state chip, category chip, tags.
  - Progress bar with state-colored fill.
  - Compact metric chips: size, uploaded, ratio, ETA, seeds, availability.
  - Footer: added time and seed/leecher info.
- Long press enters batch selection.
- Context menu exposes start, pause, force start, recheck, rename, save path, category, tags, speed limits, delete.

### RSS

RSS is a qBittorrent feature and should be visually related to mail/news management.

- Large title: RSS Subscriptions.
- Top actions: refresh and add.
- Feed cards use grouped list style, not heavy cards.
- Feed header: title, unread/article count, URL, last refresh status.
- Feed context menu: rename, refresh, delete.
- Articles:
  - unread dot, title, published date, source.
  - tap opens a bottom sheet with article detail and "add torrent" action if available.
- Empty state: one centered icon, title, and add button.
- Error state: concise message and retry button.

### Downloader Profile

Profile is a settings-style screen.

- Connection group: type, URL, version, session state.
- Speed group: current download/upload, configured limits, alternative limits.
- Library group: categories, tags, default save path.
- qBittorrent group: preferences and logs.
- Transmission group: daemon stats and queue state.

## Interaction Rules

- Use `CupertinoContextMenu` for row-level torrent actions.
- Use bottom sheets for filtering, sorting, add torrent, RSS article detail, and task detail.
- Destructive actions must use red labels and a confirmation dialog.
- Deleting local files must be a separate, explicit option.
- Batch mode should always show count, select visible, cancel, and a compact action bar.
- Pull to refresh remains available on torrent and RSS lists.
- Filters and sorts animate in 150-250 ms; no scaling hover effects that shift layout.

## State Design

- **Loading**: skeleton rows or compact spinners inside the affected control.
- **Empty torrents**: message should adapt to active filters, e.g. "No matching torrents".
- **Disconnected**: show downloader type, URL, and retry; do not hide navigation.
- **Partial failure**: keep stale data visible and show an inline error banner.
- **Long operations**: optimistic toast plus refresh after completion.

## Component Inventory

- `DownloaderCupertinoTheme`: shared app theme.
- `DownloaderStateWidget`: collapsible translucent status strip.
- `TorrentListItem`: compact grouped row with context menu.
- `FloatingTorrentToolbar`: filter/search/sort/add bar.
- `BatchSelectionBar`: glass bottom action bar.
- `RssFeedGroup`: expandable grouped RSS feed.
- `SettingsGroup`: profile/preferences grouped section.

## Accessibility

- Every icon-only control needs a tooltip and semantic label.
- Large font support should keep row text from overlapping by wrapping metadata chips.
- Active filter state cannot rely on color alone; include count/badge where possible.
- Destructive actions must be named clearly for screen readers.
- Hit targets should stay at least 44 x 44 on mobile.

## Implementation Notes

- Prefer Cupertino icons for navigation, toolbar, and contextual actions.
- Keep Material widgets where the project already depends on Material behaviors, but theme them to a Cupertino surface model.
- Use `ColorScheme` roles instead of hard-coded colors inside feature widgets.
- Avoid nested cards; use grouped surfaces for settings/RSS and compact row containers for torrents.
