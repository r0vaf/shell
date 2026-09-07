pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import Caelestia.Config
import qs.components
import qs.services
import qs.modules.nexus.common

// Generic version of AudioDeviceList for plain {label, value} choices whose
// count isn't known at compile time (resolutions, refresh rates, etc.).
ItemList {
    id: root

    // Each entry: { label: string, value: string }
    property var choices: []
    property string activeValue: ""
    property string iconName: "check"

    signal chosen(value: string)

    last: true
    showList: true

    model: ScriptModel {
        values: root.choices
    }

    delegate: Item {
        id: item

        required property var modelData
        required property int index
        readonly property bool active: item.modelData?.value === root.activeValue

        anchors.left: root.list.contentItem.left
        anchors.right: root.list.contentItem.right
        implicitHeight: rowLayout.implicitHeight + rowLayout.anchors.margins * 2

        StateLayer {
            radius: Tokens.rounding.extraSmall
            bottomLeftRadius: item.index === root?.list.count - 1 ? Tokens.rounding.extraLarge : radius
            bottomRightRadius: item.index === root?.list.count - 1 ? Tokens.rounding.extraLarge : radius
            onClicked: root.chosen(item.modelData.value)
        }

        RowLayout {
            id: rowLayout

            anchors.fill: parent
            anchors.margins: Tokens.padding.medium
            anchors.leftMargin: Tokens.padding.largeIncreased
            anchors.rightMargin: Tokens.padding.largeIncreased
            spacing: Tokens.spacing.medium

            StyledText {
                Layout.fillWidth: true
                text: item.modelData?.label ?? ""
                font: Tokens.font.body.small
                elide: Text.ElideRight
            }

            MaterialIcon {
                text: root.iconName
                color: Colours.palette.m3primary
                fontStyle: Tokens.font.icon.medium
                opacity: item.active ? 1 : 0

                Behavior on opacity {
                    Anim {
                        type: Anim.DefaultEffects
                    }
                }
            }
        }
    }
}
