pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import Caelestia.Config
import qs.components
import qs.components.controls
import qs.services
import qs.modules.nexus.common

PageBase {
    id: root

    isSubPage: true
    title: root.nState.selectedDisplayOutput

    readonly property var output: WlrRandr.outputFor(root.nState.selectedDisplayOutput)
    readonly property var monitor: {
        const screen = Screens.screens.find(s => s.name === root.nState.selectedDisplayOutput);
        return screen ? Brightness.getMonitorForScreen(screen) : null;
    }

    // Unique resolutions, largest first.
    readonly property var resolutionChoices: {
        if (!root.output)
            return [];
        const seen = new Set();
        const out = [];
        for (const m of root.output.modes) {
            if (seen.has(m.res))
                continue;
            seen.add(m.res);
            out.push({
                label: m.res,
                value: m.res
            });
        }
        out.sort((a, b) => {
            const [aw, ah] = a.value.split("x").map(Number);
            const [bw, bh] = b.value.split("x").map(Number);
            return bw * bh - aw * ah;
        });
        return out;
    }

    readonly property var refreshChoices: {
        if (!root.output)
            return [];
        return root.output.modes.filter(m => m.res === root.output.currentMode).map(m => ({
                    label: `${Math.round(parseFloat(m.hz))} Hz`,
                    value: m.hz
                }));
    }

    readonly property var scalePresets: [1.0, 1.25, 1.5, 1.75, 2.0]
    readonly property var rotationChoices: [
        {
            label: qsTr("Normal"),
            value: "normal"
        },
        {
            label: qsTr("90°"),
            value: "90"
        },
        {
            label: qsTr("180°"),
            value: "180"
        },
        {
            label: qsTr("270°"),
            value: "270"
        }
    ]

    ColumnLayout {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        width: root.cappedWidth
        spacing: Tokens.spacing.extraSmall / 2

        // Resolution
        SectionHeader {
            first: true
            text: qsTr("Resolution")
        }

        ChoiceList {
            Layout.fillWidth: true
            first: true
            choices: root.resolutionChoices
            activeValue: root.output?.currentMode ?? ""
            onChosen: value => {
                const hz = root.output.modes.find(m => m.res === value)?.hz ?? root.output.currentHz;
                WlrRandr.setMode(root.output.name, value, hz);
            }
        }

        // Refresh rate
        SectionHeader {
            text: qsTr("Refresh rate")
        }

        ChoiceList {
            Layout.fillWidth: true
            first: true
            choices: root.refreshChoices
            activeValue: root.output?.currentHz ?? ""
            onChosen: value => WlrRandr.setMode(root.output.name, root.output.currentMode, value)
        }

        // Scale
        SectionHeader {
            text: qsTr("Scale")
        }

        RowLayout {
            Layout.fillWidth: true
            spacing: Tokens.spacing.small

            Repeater {
                model: root.scalePresets

                IconTextButton {
                    required property real modelData

                    Layout.fillWidth: true
                    text: modelData.toFixed(2) + "x"
                    isRound: true
                    type: Math.abs((root.output?.scale ?? 1) - modelData) < 0.001 ? IconTextButton.Filled : IconTextButton.Tonal
                    onClicked: WlrRandr.setScale(root.output.name, modelData)
                }
            }
        }

        StepperRow {
            last: true
            label: qsTr("Custom scale")
            value: root.output?.scale ?? 1.0
            from: 0.5
            to: 3.0
            stepSize: 0.05
            onMoved: v => WlrRandr.setScale(root.output.name, v)
        }

        // Rotation
        SectionHeader {
            text: qsTr("Rotation")
        }

        RowLayout {
            Layout.fillWidth: true
            spacing: Tokens.spacing.small

            Repeater {
                model: root.rotationChoices

                IconTextButton {
                    required property var modelData

                    Layout.fillWidth: true
                    text: modelData.label
                    isRound: true
                    type: (root.output?.transform ?? "normal") === modelData.value ? IconTextButton.Filled : IconTextButton.Tonal
                    onClicked: WlrRandr.setTransform(root.output.name, modelData.value)
                }
            }
        }

        // Brightness
        SectionHeader {
            visible: root.monitor !== null
            text: qsTr("Brightness")
        }

        SliderRow {
            visible: root.monitor !== null
            first: true
            last: true
            icon: "brightness_6"
            label: qsTr("Brightness")
            valueLabel: Math.round(value * 100) + "%"
            value: root.monitor?.brightness ?? 1
            onMoved: v => root.monitor?.setBrightness(v)
        }

        // Adaptive sync
        SectionHeader {
            text: qsTr("Adaptive sync")
        }

        ToggleRow {
            first: true
            last: true
            text: qsTr("Enabled")
            subtext: qsTr("Variable refresh rate")
            checked: (root.output?.adaptive ?? "disabled") === "enabled"
            onToggled: WlrRandr.setAdaptive(root.output.name, checked)
        }
    }
}
