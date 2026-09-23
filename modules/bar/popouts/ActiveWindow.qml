import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Widgets
import Caelestia.Config
import qs.components
import qs.services
import qs.utils

Item {
    id: root

    required property PopoutState popouts

    required property ShellScreen screen

    implicitWidth: list.count > 0 ? child.implicitWidth : -Tokens.padding.extraLargeIncreased
    implicitHeight: child.implicitHeight

    Column {
        id: child

        anchors.top: parent.top
        anchors.horizontalCenter: parent.horizontalCenter
        spacing: Tokens.spacing.medium
        width: list.width

        ListView {
            id: list

            width: Tokens.sizes.bar.windowPreviewSize
            height: Math.min(contentHeight, 280)
            clip: true
            spacing: Tokens.spacing.small
            model: Hypr.toplevels
            boundsBehavior: Flickable.StopAtBounds


            delegate: RowLayout {
                id: row

                required property var modelData

                width: ListView.view.width
                spacing: Tokens.spacing.medium

                IconImage {
                    id: rowIcon

                    Layout.alignment: Qt.AlignVCenter
                    implicitSize: rowDetails.implicitHeight
                    source: Icons.getAppIcon(row.modelData.appId ?? "", "image-missing")
                }

                ColumnLayout {
                    id: rowDetails

                    spacing: 0
                    Layout.fillWidth: true

                    StyledText {
                        Layout.fillWidth: true
                        text: row.modelData.title || Tr.tr("Unknown")
                        font: Tokens.font.body.medium
                        elide: Text.ElideRight
                        color: row.modelData.activated ? Colours.palette.m3primary : Colours.palette.m3onSurface
                    }

                    StyledText {
                        Layout.fillWidth: true
                        text: row.modelData.appId ?? ""
                        color: row.modelData.activated ? Colours.palette.m3primary : Colours.palette.m3onSurfaceVariant
                        elide: Text.ElideRight
                    }
                }
            }
        }
    }
}
