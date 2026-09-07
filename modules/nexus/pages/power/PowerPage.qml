pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Caelestia.Config
import qs.components
import qs.components.controls
import qs.services
import qs.modules.nexus.common

PageBase {
    id: root

    title: qsTr("Power")

    readonly property list<MenuItem> profileItems: [
        MenuItem {
            text: qsTr("Performance")
        },
        MenuItem {
            text: qsTr("Balanced")
        },
        MenuItem {
            text: qsTr("Power saver")
        }
    ]

    readonly property list<MenuItem> timeoutItems: [
        MenuItem {
            text: qsTr("Off")
        },
        MenuItem {
            text: qsTr("5 minutes")
        },
        MenuItem {
            text: qsTr("10 minutes")
        },
        MenuItem {
            text: qsTr("15 minutes")
        },
        MenuItem {
            text: qsTr("20 minutes")
        },
        MenuItem {
            text: qsTr("30 minutes")
        },
        MenuItem {
            text: qsTr("60 minutes")
        }
    ]
    readonly property var timeoutSeconds: [-1, 300, 600, 900, 1200, 1800, 3600]

    function timeoutIdx(seconds: int): int {
        const i = root.timeoutSeconds.indexOf(seconds);
        return i === -1 ? 0 : i;
    }

    ColumnLayout {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        width: root.cappedWidth
        spacing: Tokens.spacing.extraSmall / 2

        // Power profile
        SectionHeader {
            first: true
            visible: PowerProfiles.available
            text: qsTr("Power profile")
        }

        SelectRow {
            visible: PowerProfiles.available
            first: true
            last: true
            label: qsTr("Profile")
            menuItems: root.profileItems
            active: root.profileItems[Math.max(0, PowerProfiles.profiles.indexOf(PowerProfiles.profile))]
            onSelected: item => PowerProfiles.setProfile(PowerProfiles.profiles[root.profileItems.indexOf(item)])
        }

        // Idle & lock
        SectionHeader {
            text: qsTr("Idle & lock")
        }

        RowButton {
            first: true
            icon: "lock"
            text: qsTr("Lock now")
            trailingIcon: ""
            onClicked: IdlePower.lockNow()
        }

        StyledText {
            Layout.fillWidth: true
            Layout.topMargin: Tokens.spacing.small
            Layout.bottomMargin: Tokens.spacing.extraSmall
            Layout.leftMargin: Tokens.padding.small
            text: qsTr("Plugged in")
            color: Colours.palette.m3onSurfaceVariant
            font: Tokens.font.label.medium
            elide: Text.ElideRight
        }

        SelectRow {
            first: true
            label: qsTr("Auto-lock")
            menuItems: root.timeoutItems
            active: root.timeoutItems[root.timeoutIdx(IdlePower.getProfileTimeout("ac", "lock"))]
            onSelected: item => IdlePower.setProfileTimeout("ac", "lock", root.timeoutSeconds[root.timeoutItems.indexOf(item)])
        }

        SelectRow {
            label: qsTr("Screen off")
            menuItems: root.timeoutItems
            active: root.timeoutItems[root.timeoutIdx(IdlePower.getProfileTimeout("ac", "dpms"))]
            onSelected: item => IdlePower.setProfileTimeout("ac", "dpms", root.timeoutSeconds[root.timeoutItems.indexOf(item)])
        }

        SelectRow {
            last: true
            label: qsTr("Auto-suspend")
            menuItems: root.timeoutItems
            active: root.timeoutItems[root.timeoutIdx(IdlePower.getProfileTimeout("ac", "suspend"))]
            onSelected: item => IdlePower.setProfileTimeout("ac", "suspend", root.timeoutSeconds[root.timeoutItems.indexOf(item)])
        }

        StyledText {
            Layout.fillWidth: true
            Layout.topMargin: Tokens.spacing.small
            Layout.bottomMargin: Tokens.spacing.extraSmall
            Layout.leftMargin: Tokens.padding.small
            text: qsTr("On battery")
            color: Colours.palette.m3onSurfaceVariant
            font: Tokens.font.label.medium
            elide: Text.ElideRight
        }

        SelectRow {
            first: true
            label: qsTr("Auto-lock")
            menuItems: root.timeoutItems
            active: root.timeoutItems[root.timeoutIdx(IdlePower.getProfileTimeout("battery", "lock"))]
            onSelected: item => IdlePower.setProfileTimeout("battery", "lock", root.timeoutSeconds[root.timeoutItems.indexOf(item)])
        }

        SelectRow {
            label: qsTr("Screen off")
            menuItems: root.timeoutItems
            active: root.timeoutItems[root.timeoutIdx(IdlePower.getProfileTimeout("battery", "dpms"))]
            onSelected: item => IdlePower.setProfileTimeout("battery", "dpms", root.timeoutSeconds[root.timeoutItems.indexOf(item)])
        }

        SelectRow {
            last: true
            label: qsTr("Auto-suspend")
            menuItems: root.timeoutItems
            active: root.timeoutItems[root.timeoutIdx(IdlePower.getProfileTimeout("battery", "suspend"))]
            onSelected: item => IdlePower.setProfileTimeout("battery", "suspend", root.timeoutSeconds[root.timeoutItems.indexOf(item)])
        }
    }
}
