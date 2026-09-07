pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Caelestia.Config
import qs.components
import qs.services
import qs.utils
import qs.modules.launcher.services

// Fills the space left empty by the (non-functional, protocol-blocked)
// workspaces/activeWindow widgets with something that actually works: a
// quick-launch dock for your favourited apps (same favourites list already
// managed via the Apps settings page). Not a real taskbar -- it doesn't
// reflect which apps are currently open, since that needs window data rill
// doesn't expose. Just fast access to the apps you use most.
StyledRect {
    id: root

    readonly property alias items: items

    implicitWidth: Tokens.sizes.bar.innerWidth
    implicitHeight: layout.implicitHeight + Tokens.padding.medium * 2

    visible: items.count > 0
    color: Qt.alpha(Colours.tPalette.m3surfaceContainer, items.count > 0 ? Colours.tPalette.m3surfaceContainer.a : 0)
    radius: Tokens.rounding.full

    Column {
        id: layout

        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        anchors.topMargin: Tokens.padding.medium
        spacing: Tokens.spacing.small

        add: Transition {
            Anim {
                properties: "scale"
                from: 0
                to: 1
                easing: Tokens.anim.standardDecel
            }
        }

        move: Transition {
            Anim {
                properties: "scale"
                to: 1
                easing: Tokens.anim.standardDecel
            }
            Anim {
                properties: "x,y"
            }
        }

        Repeater {
            id: items

            model: ScriptModel {
                values: [...Apps.list].filter(a => Strings.testRegexList(GlobalConfig.launcher.favouriteApps, a.id))
            }

            FavouriteAppItem {}
        }
    }

    Behavior on implicitHeight {
        Anim {}
    }
}
