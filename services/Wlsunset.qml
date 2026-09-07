pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    // -1 means off
    readonly property alias temp: persisted.temp
    readonly property bool active: persisted.temp > 0
    property bool available: true

    function setTemp(kelvin: int): void {
        Quickshell.execDetached(["sh", "-c", "pkill wlsunset 2>/dev/null; wlsunset -T " + kelvin + " -t " + kelvin]);
        persisted.temp = kelvin;
    }

    function turnOff(): void {
        Quickshell.execDetached(["pkill", "wlsunset"]);
        persisted.temp = -1;
    }

    PersistentProperties {
        id: persisted

        property int temp: -1

        reloadableId: "wlsunset"
    }

    // Checks wlsunset is installed and re-applies the persisted temperature
    // on shell startup — this is what let you retire the NIGHTLIGHT_TEMP
    // handling in quicksettings-restore.sh.
    Component.onCompleted: {
        checkProc.running = true;
        if (persisted.temp > 0)
            Quickshell.execDetached(["sh", "-c", "pkill wlsunset 2>/dev/null; wlsunset -T " + persisted.temp + " -t " + persisted.temp]);
    }

    Process {
        id: checkProc

        command: ["sh", "-c", "command -v wlsunset >/dev/null 2>&1 && echo yes || echo no"]
        stdout: StdioCollector {
            onStreamFinished: root.available = text.trim() === "yes"
        }
    }
}
