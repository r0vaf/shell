# Caelestia-shell on rill — cut features & future improvements

Everything below is disabled/removed because it depends on data or a control
channel rill doesn't currently expose (no `wlr-foreign-toplevel-management`,
no `ext-workspace`, no `river-status`, no control-socket equivalent to
`hyprctl`/`riverctl`). All of it becomes fixable if the rill-side status
socket work discussed earlier ever gets built.

---

## 1. Workspace indicator (bar)
**UI location:** bar, left side, right after the logo — was a row of numbered
pills, one per workspace, current one highlighted, "special workspace"
markers when open.
**Why cut:** needs live workspace list + active-workspace id. No data source.
**Visual change:** that whole pill-row segment is gone. The bar's left
cluster is now just: logo → (empty space where workspaces were) → spacer.
**Disabled via:** `bar.entries` config, `workspaces` entry set to disabled.
**Fix path:** rill status-socket work (see earlier conversation) — would
restore this close to 1:1, since it's pure display, no write actions needed
for the pills themselves (only the *click-to-switch* interaction needs a
write channel, see below).

## 2. Active-window widget (bar) + windowinfo popout module
**UI location:** bar, center-right — was the focused app's icon + title,
plus a hover popout (`modules/windowinfo/`) showing a live preview/details
of the focused window.
**Why cut:** needs live focused-toplevel data (title, icon, geometry) plus a
screencopy source for the preview. Toplevel *listing* is technically wired
up (`Quickshell.Wayland.ToplevelManager`) and would populate automatically
if rill ever advertises `zwlr_foreign_toplevel_manager_v1`, but as of this
port it doesn't, so this renders nothing.
**Visual change:** bar center segment gone entirely; the hover-preview
popout never triggers since its bar anchor doesn't exist.
**Disabled via:** `bar.entries` (`activeWindow` entry) + `bar.popouts.activeWindow`.
**Fix path:** same status-socket work covers the title/icon. The
live-preview thumbnail specifically also needs `wlr-screencopy` pointed at
a real toplevel handle — a separate, smaller piece once toplevel data exists.

## 3. Click-to-switch / scroll-to-switch workspace (bar interaction)
**UI location:** same bar region as #1 — scrolling over the workspace pills,
or clicking one, used to call `Hypr.dispatch("workspace ...")`.
**Why cut:** no write/control channel into rill exists (confirmed earlier —
no `riverctl` equivalent). Currently a logged no-op if triggered, but since
#1 is removed there's nothing left to click/scroll over anyway.
**Visual change:** none beyond #1 (nothing to interact with).
**Fix path:** needs rill to grow *some* control channel, not just a status
feed — bigger ask than #1's read-only fix.

## 4. Idle-triggered DPMS off/on (screen blanking on idle)
**UI location:** not visible UI, but a real behavior — the shell's idle
timers (configured screen-off after N minutes) silently do nothing when they
reach the DPMS-off/on stage, since that action still routes through
`Hypr.dispatch("dpms off")`.
**Why cut:** Hyprland-specific dispatch syntax, no equivalent wired up yet.
**Visual change:** none in the UI itself — the practical effect is your
screen just won't blank on idle timeout anymore (lock-on-idle, if
separately configured, is unaffected — that path doesn't go through dispatch).
**Fix path:** needs a real replacement command (e.g. `wlopm` if installed, or
whatever DPMS tool exists in your setup) swapped into `IdleMonitors.qml`'s
dispatch branch — small, self-contained fix, just needs picking a tool.

## 5. Fullscreen-aware notification suppression
**UI location:** notifications — was meant to auto-suppress popups while a
fullscreen app (e.g. a game, a video) has focus.
**Why cut:** needs the same workspace/fullscreen data as #1.
**Visual change:** notification popups will now always show, even over
fullscreen content, unless you use the manual DND toggle (already present in
the shell, works fine — this is purely about the *automatic* version).
**Fix path:** covered by the same status-socket fix as #1.

## 6. GameMode auto-detection
**UI location:** not directly visible — was meant to auto-flip a "game
mode" state (likely affecting notification/DND behavior, possibly
performance-related toggles) when a fullscreen game is focused.
**Why cut:** same fullscreen-detection dependency as #5.
**Visual change:** none automatic; if GameMode has a manual toggle elsewhere
in the shell, that still works.

## 7. Per-monitor idle-timeout scaling + caps/num-lock bar indicators
**Why cut:** minor — per-monitor idle scaling needs monitor list data;
caps/num-lock indicators were sourced via Hyprland's native IPC plugin.
**Visual change:** idle timeout uses a single global value instead of
per-monitor; caps/num-lock indicator in the bar (if enabled in
`statusIcons`) will show its default/off state rather than tracking real
key state.
**Fix path:** idle-scaling needs the status socket; caps/num-lock is
independent — could be read directly from libinput/evdev without needing
any rill changes at all, just unwritten so far.

---

## Everything NOT on this list works normally
Dashboard, launcher, sidebar, notifications (once repointed at caelestia's
own `NotificationServer`, see step-by-step doc), OSD, lock screen, session
menu, all the hardware-service widgets (cpu/gpu/memory/disk/audio/battery/
network/temperature/brightness) — none of that touches Hyprland at all in
the original codebase, so none of it is affected by this port.

## Revisit if rill ever gains protocol/IPC support

If rill adds `zwlr_foreign_toplevel_manager_v1` support, or a rill-side
status-socket gets built (previously considered, shelved), upstream's
`cycleSpecialWorkspace()` and `toplevelsForWs()` in services/Hypr.qml
(as of the caelestia-dots merge around 2026-09) are worth revisiting as
a reference implementation -- discarded during this merge only because
they depend entirely on Hyprland IPC that has no rill equivalent yet,
not because the logic itself is bad.
