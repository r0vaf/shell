import QtQuick
import qs.services

// Replacement for the Hyprland-GlobalShortcut-backed CustomShortcut. Same
// declarative interface as before (name, description, onPressed,
// onReleased) so every call site elsewhere in the shell (Shortcuts.qml etc.)
// is unchanged. Firing is now driven by ShortcutRegistry via Quickshell IPC
// instead of a Hyprland-only Wayland protocol -- see ShortcutRegistry.qml
// for the rill config.zon side of this.
QtObject {
    id: root

    property string name: ""
    property string description: ""

    signal pressed
    signal released

    Component.onCompleted: ShortcutRegistry.register(name, root)
    Component.onDestruction: ShortcutRegistry.unregister(name)
}
