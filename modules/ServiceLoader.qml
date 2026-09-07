import QtQuick
import Quickshell
import Caelestia.Config
import qs.services

Scope {
    Component.onCompleted: {
        // Force certain singletons to load on shell init instead of lazily

        IdleInhibitor;
        GameMode;
        Notifs;
        Players;
        Brightness;
        Weather.reload();

        // Added for Display/Power Nexus pages — without this these are pure
        // lazy singletons that never instantiate (and so never run their
        // startup restore / AC-watch logic) unless/until the user happens to
        // open the page that references them.
        IdlePower;
        WlrRandr;
        Wlsunset;
        PowerProfiles;

        if (GlobalConfig.utilities.vpn.enabled)
            VPN;
    }
}
