pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    property string profile: ""
    property bool available: false
    readonly property var profiles: ["performance", "balanced", "power-saver"]

    function setProfile(p: string): void {
        if (!root.profiles.includes(p))
            return;
        root.profile = p; // optimistic
        Quickshell.execDetached(["powerprofilesctl", "set", p]);
        confirmTimer.restart();
    }

    function refresh(): void {
        getProc.running = true;
    }

    Component.onCompleted: checkProc.running = true

    Process {
        id: checkProc

        command: ["sh", "-c", "command -v powerprofilesctl >/dev/null 2>&1 && echo yes || echo no"]
        stdout: StdioCollector {
            onStreamFinished: {
                root.available = text.trim() === "yes";
                if (root.available)
                    root.refresh();
            }
        }
    }

    Process {
        id: getProc

        command: ["powerprofilesctl", "get"]
        stdout: StdioCollector {
            onStreamFinished: {
                const p = text.trim();
                if (p)
                    root.profile = p;
            }
        }
    }

    // Re-reads shortly after a set() to confirm it actually took (e.g. if
    // power-profiles-daemon rejected it because the profile isn't supported
    // on this hardware).
    Timer {
        id: confirmTimer
        interval: 500
        onTriggered: root.refresh()
    }
}
