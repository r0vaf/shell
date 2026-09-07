pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Widgets
import Caelestia.Config
import qs.services

// Modeled on TrayItem.qml (same size, same click pattern) but launches a
// favourited app instead of activating a tray item.
//
// modelData is a caelestia::AppEntry (what Apps.list/appDb.apps actually
// yields), NOT a DesktopEntry -- confirmed via the C++ source
// (plugin/src/Caelestia/appdb.hpp). AppEntry is a wrapper: its own
// properties are just id/name/comment/execString/startupClass/genericName/
// categories/keywords/frequency (notably no `icon`), and the real
// DesktopEntry lives behind its `entry` property. Every access below goes
// through modelData.entry for that reason.
MouseArea {
    id: root

    // var, not DesktopEntry -- the strict type silently fails to bind
    // AppEntry objects to a DesktopEntry-typed required property, leaving
    // it null with no visible error (confirmed via debug logging earlier).
    required property var modelData

    readonly property QtObject entry: modelData?.entry ?? null

    acceptedButtons: Qt.LeftButton

    implicitWidth: Tokens.font.body.small.pointSize * 2
    implicitHeight: Tokens.font.body.small.pointSize * 2

    onClicked: {
        if (!root.entry)
            return;
        if (root.entry.runInTerminal)
            Quickshell.execDetached({
                command: [...GlobalConfig.general.apps.terminal, `${Quickshell.shellDir}/assets/wrap_term_launch.sh`, ...root.entry.command],
                workingDirectory: root.entry.workingDirectory
            });
        else
            root.entry.execute();
    }

    IconImage {
        anchors.fill: parent
        asynchronous: true
        source: Quickshell.iconPath(root.entry?.icon, "image-missing")
    }
}
