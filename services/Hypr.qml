pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Io

// Replacement for the original Hyprland-backed Hypr.qml, ported for rill/river.
//
// Same public property/method surface as the original, so the ~20 consuming
// files elsewhere in the shell need little or no change. Real data where a
// source exists (window list, via wlr-foreign-toplevel-management), safe
// stubs everywhere else (workspaces, monitors, keyboard state) since rill
// currently exposes no protocol or IPC channel for that.
//
// dispatch() is a logged no-op: there is no control socket into rill (no
// riverctl-equivalent exists), so every UI action that used to call
// Hypr.dispatch(...) (workspace switch by clicking a pill, move/pin/kill
// window, DPMS toggle) currently does nothing but log what it *would* have
// sent. Search this file's callers for Hypr.dispatch to find and wire up
// each action individually once/if rill grows a control channel.
Singleton {
    id: root

    // --- window list: real data, via wlr-foreign-toplevel-management ---
    // Requires zwlr_foreign_toplevel_manager_v1. Confirmed via `wayland-info`
    // that rill does NOT currently advertise this, so `toplevels.values` will
    // be an empty list until/unless that changes. Left wired up rather than
    // stubbed so it starts working automatically if that ever changes.
    readonly property var toplevels: ToplevelManager.toplevels
    readonly property var activeToplevel: {
        for (const t of toplevels.values ?? [])
            if (t.activated)
                return t;
        return null;
    }

    // --- workspaces/monitors: no data source on rill, stubbed empty ---
    readonly property var workspaces: ({ values: [] })
    readonly property var monitors: ({ values: [] })
    readonly property var focusedWorkspace: null
    readonly property var focusedMonitor: null
    readonly property int activeWsId: 1
    readonly property bool usingLua: false

    function monitorFor(screen): var {
        return null;
    }

    // --- keyboard state: no source wired yet ---
    // TODO: original read this via a native Hyprland IPC plugin
    // (hyprdevices.cpp). On rill this would need to come from libinput/evdev
    // directly -- not wired up yet, so caps/num lock indicators and layout
    // will just show their default/off state.
    readonly property bool capsLock: false
    readonly property bool numLock: false
    readonly property string defaultKbLayout: "??"
    readonly property string kbLayoutFull: "Unknown"
    readonly property string kbLayout: "??"

    // --- extras/options/devices: minimal stub so property access doesn't crash ---
    readonly property var extras: QtObject {
        id: extrasObj

        readonly property var options: QtObject {}
        readonly property var devices: QtObject {
            readonly property var keyboards: []
        }
        function refreshDevices(): void {}
        function batchMessage(msgs): void {}
    }
    readonly property alias options: extrasObj.options
    readonly property alias devices: extrasObj.devices

    signal configReloaded

    // Logged no-op. See file header -- no control channel into rill exists yet.
    function dispatch(request: string): void {
        console.warn("[Rill/Hypr stub] dispatch() called with no rill control channel, ignored:", request);
    }
}
