pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Caelestia.Config
import qs.components
import qs.services
import qs.modules.nexus.common

PageBase {
    id: root

    isSubPage: true
    title: qsTr("Arrange displays")

    readonly property var primary: WlrRandr.outputs.find(o => o.name === "eDP-1") ?? WlrRandr.outputs[0]

    ColumnLayout {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        width: root.cappedWidth
        spacing: Tokens.spacing.extraSmall / 2

        SectionHeader {
            first: true
            text: qsTr("Layout")
        }

        RowButton {
            first: true
            icon: "flip_to_front"
            text: qsTr("Mirror")
            subtext: qsTr("Align all displays at 0,0")
            trailingIcon: ""
            onClicked: WlrRandr.arrange("mirror")
        }

        RowButton {
            icon: "arrow_forward"
            text: qsTr("Extend right")
            subtext: qsTr("Place additional displays to the right of %1").arg(root.primary?.name ?? "")
            trailingIcon: ""
            onClicked: WlrRandr.arrange("extend-right")
        }

        RowButton {
            last: true
            icon: "arrow_upward"
            text: qsTr("Extend above")
            subtext: qsTr("Place additional displays above %1").arg(root.primary?.name ?? "")
            trailingIcon: ""
            onClicked: WlrRandr.arrange("extend-above")
        }
    }
}
