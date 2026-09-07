pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

// Replaces Hyprland's GlobalShortcut mechanism (components/misc/CustomShortcut.qml
// used to wrap Quickshell.Hyprland.GlobalShortcut directly, which rides on a
// Hyprland-only Wayland extension). rill has no equivalent hotkey-grab
// protocol, so the flow is inverted: rill's own config.zon binds a key to
// spawning a shell command, which calls into this already-running shell over
// Quickshell's IPC mechanism, which then fires the matching CustomShortcut's
// pressed/released signal.
//
// Wire up a key in ~/.config/rill/config.zon like:
//   .{ .key = .{ .super = true }, .keysym = .N, .command = "qs -c caelestia ipc call shortcut trigger nexus" },
// (adjust to rill's actual config.zon bind syntax -- confirm against your
// current config, this mirrors the pattern used for rovafbar's menu toggle.)
Singleton {
    id: root

    property var shortcuts: ({})

    function register(name: string, shortcut: var): void {
        shortcuts[name] = shortcut;
    }

    function unregister(name: string): void {
        delete shortcuts[name];
    }

    function trigger(name: string): void {
        const s = shortcuts[name];
        if (s)
            s.pressed();
        else
            console.warn("[ShortcutRegistry] no shortcut registered for name:", name);
    }

    function release(name: string): void {
        const s = shortcuts[name];
        if (s)
            s.released();
    }

    IpcHandler {
        target: "shortcut"

        function trigger(name: string): void {
            root.trigger(name);
        }

        function release(name: string): void {
            root.release(name);
        }
    }
}
