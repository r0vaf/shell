pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Caelestia.Config
import qs.components
import qs.services
import qs.modules.nexus.common

PageBase {
    id: root

    title: qsTr("Display")

    // Common night-light presets (matches quicksettings.sh's "Turn On
    // (4000K)" default plus a couple of common alternatives).
    readonly property var presets: [4000, 3500, 5000]

    ColumnLayout {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        width: root.cappedWidth
        spacing: Tokens.spacing.extraSmall / 2

        // Outputs
        SectionHeader {
            first: true
            text: qsTr("Outputs")
        }

        Repeater {
            model: Screens.screens

            NavRow {
                required property var modelData
                required property int index

                Layout.fillWidth: true
                first: index === 0
                last: index === Screens.screens.length - 1 && Screens.screens.length <= 1

                icon: "monitor"
                text: modelData.name
                subtext: {
                    const o = WlrRandr.outputFor(modelData.name);
                    if (!o)
                        return qsTr("Unknown");
                    return `${o.currentMode} @ ${Math.round(parseFloat(o.currentHz))}Hz`;
                }
                onClicked: {
                    root.nState.selectedDisplayOutput = modelData.name;
                    root.nState.openSubPage(1);
                }
            }
        }

        NavRow {
            visible: Screens.screens.length > 1
            last: true
            icon: "dock_to_right"
            text: qsTr("Arrange displays")
            subtext: qsTr("Mirror or extend")
            onClicked: root.nState.openSubPage(2)
        }

        // Night Light
        SectionHeader {
            text: qsTr("Night Light")
        }

        ToggleRow {
            first: true
            text: qsTr("Enabled")
            subtext: Wlsunset.active ? qsTr("%1K").arg(Wlsunset.temp) : qsTr("Off")
            checked: Wlsunset.active
            onToggled: checked ? Wlsunset.setTemp(root.presets[0]) : Wlsunset.turnOff()
        }

        StepperRow {
            last: true
            visible: Wlsunset.active
            label: qsTr("Colour temperature")
            subtext: qsTr("Lower is warmer")
            value: Wlsunset.temp > 0 ? Wlsunset.temp : root.presets[0]
            from: 2500
            to: 6500
            stepSize: 100
            onMoved: v => Wlsunset.setTemp(v)
        }
    }
}
