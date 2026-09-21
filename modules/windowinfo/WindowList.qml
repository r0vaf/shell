pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import Caelestia.Config
import Caelestia.I18n
import qs.components
import qs.services
import qs.utils

Item {
    id: root

    required property ShellScreen screen

    signal closeRequested

    // Clicked entry, otherwise follow the focused window.
    property var selected: null
    readonly property var shown: selected ?? Hypr.activeToplevel

    implicitWidth: child.implicitWidth + Tokens.padding.large * 2
    implicitHeight: screen.height * Tokens.sizes.winfo.heightMult

    function appName(t): string {
        if (t?.appId) {
            const entry = DesktopEntries.heuristicLookup(t.appId);
            return entry?.name ?? t.appId;
        }
        return t?.title || Tr.tr("Unknown");
    }

    function stateText(t): string {
        if (!t)
            return "-";
        const s = [];
        if (t.activated)
            s.push(Tr.tr("focused"));
        if (t.maximized)
            s.push(Tr.tr("maximized"));
        if (t.minimized)
            s.push(Tr.tr("minimized"));
        if (t.fullscreen)
            s.push(Tr.tr("fullscreen"));
        return s.join(", ") || "-";
    }

    StyledRect {
        z: 1

        anchors.top: parent.top
        anchors.right: parent.right
        anchors.margins: Tokens.padding.large * 2

        implicitWidth: closeText.implicitHeight + Tokens.padding.large
        implicitHeight: implicitWidth
        radius: width / 2
        color: Colours.palette.m3secondaryContainer

        StyledText {
            id: closeText

            anchors.centerIn: parent
            text: "×"
            color: Colours.palette.m3onSecondaryContainer
        }

        MouseArea {
            anchors.fill: parent
            onClicked: root.closeRequested()
        }
    }

    RowLayout {
        id: child

        anchors.fill: parent
        anchors.margins: Tokens.padding.large
        spacing: Tokens.spacing.medium

        // Left: every open window, by application name.
        StyledRect {
            Layout.preferredWidth: Tokens.sizes.winfo.detailsWidth
            Layout.fillHeight: true

            color: Colours.tPalette.m3surfaceContainer
            radius: Tokens.rounding.large
            clip: true

            StyledText {
                anchors.centerIn: parent
                visible: windows.count === 0
                text: Tr.tr("No open windows")
            }

            ListView {
                id: windows

                anchors.fill: parent
                anchors.margins: Tokens.padding.large
                spacing: Tokens.spacing.small
                clip: true
                model: Hypr.toplevels

                delegate: StyledRect {
                    id: row

                    required property var modelData

                    width: ListView.view.width
                    implicitHeight: label.implicitHeight + Tokens.padding.large
                    radius: Tokens.rounding.large
                    color: modelData === root.shown ? Colours.palette.m3secondaryContainer : "transparent"

                    StyledText {
                        id: label

                        anchors.verticalCenter: parent.verticalCenter
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.margins: Tokens.padding.large
                        elide: Text.ElideRight
                        text: root.appName(row.modelData)
                        color: row.modelData.activated ? Colours.palette.m3primary : Colours.palette.m3onSurface
                    }

                    MouseArea {
                        anchors.fill: parent
                        onClicked: root.selected = row.modelData
                    }
                }
            }
        }

        // Right: preview, details and actions for the selected window.
        ColumnLayout {
            Layout.preferredWidth: Tokens.sizes.winfo.detailsWidth
            Layout.fillHeight: true
            spacing: Tokens.spacing.medium

            StyledRect {
                Layout.fillWidth: true
                Layout.preferredHeight: Tokens.sizes.winfo.detailsWidth * 0.4

                color: Colours.tPalette.m3surfaceContainer
                radius: Tokens.rounding.large

                Image {
                    anchors.centerIn: parent
                    width: Math.min(parent.width, parent.height) * 0.7
                    height: width
                    sourceSize: Qt.size(width, height)
                    fillMode: Image.PreserveAspectFit
                    source: Icons.getAppIcon(root.shown?.appId ?? "", "image-missing")
                }
            }

            StyledRect {
                Layout.fillWidth: true
                Layout.fillHeight: true

                color: Colours.tPalette.m3surfaceContainer
                radius: Tokens.rounding.large
                clip: true

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: Tokens.padding.large
                    spacing: Tokens.spacing.small

                    StyledText {
                        Layout.fillWidth: true
                        elide: Text.ElideRight
                        text: root.shown?.title ?? Tr.tr("No window selected")
                    }
                    StyledText {
                        Layout.fillWidth: true
                        elide: Text.ElideRight
                        text: Tr.tr("Application: %1").arg(root.appName(root.shown))
                    }
                    StyledText {
                        Layout.fillWidth: true
                        elide: Text.ElideRight
                        text: Tr.tr("App ID: %1").arg(root.shown?.appId || "-")
                    }
                    StyledText {
                        Layout.fillWidth: true
                        elide: Text.ElideRight
                        text: Tr.tr("State: %1").arg(root.stateText(root.shown))
                    }
                    Item {
                        Layout.fillHeight: true
                    }
                }
            }
        }
    }
}
