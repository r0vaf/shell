pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import Caelestia.Config
import Caelestia.I18n
import qs.components
import qs.services

Item {
    id: root

    required property ShellScreen screen

    implicitWidth: list.implicitWidth + Tokens.padding.large * 2
    implicitHeight: list.implicitHeight + Tokens.padding.large * 2

    // Desktop-entry name when there is one (e.g. "Firefox"), else the appId,
    // else the window title for clients that set no appId.
    function appName(t): string {
        if (t?.appId) {
            const entry = DesktopEntries.heuristicLookup(t.appId);
            return entry?.name ?? t.appId;
        }
        return t?.title || Tr.tr("Unknown");
    }

    ColumnLayout {
        id: list

        anchors.fill: parent
        anchors.margins: Tokens.padding.large
        spacing: Tokens.spacing.small

        StyledText {
            visible: windows.count === 0
            text: Tr.tr("No open windows")
        }

        Repeater {
            id: windows

            model: Hypr.toplevels

            delegate: StyledText {
                id: row

                required property var modelData

                text: root.appName(modelData)
                color: modelData.activated ? Colours.palette.m3primary : Colours.palette.m3onSurface

                MouseArea {
                    anchors.fill: parent
                    onClicked: row.modelData.activate()
                }
            }
        }
    }
}
