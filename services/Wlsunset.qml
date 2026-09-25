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
        Quickshell.execDetached(["sh", "-c", "pkill wlsunset 2>/dev/null; wlsunset -S 00:00 -s 00:01 -T 6501 -t " + kelvin]);
        persisted.temp = kelvin;
    }

    function turnOff(): void {
        Quickshell.execDetached(["pkill", "wlsunset"]);
        persisted.temp = -1;
    }

    // Guards applyStartupTemp() so it only fires once, the first time
    // persisted.temp reflects real loaded data (or confirmed absence of a
    // file). blockLoading on FileView does NOT guarantee adapter properties
    // are populated synchronously - only text()/data() calls block - so the
    // restore has to react to the adapter's own change signal instead of
    // assuming a fixed point (e.g. Component.onCompleted) is late enough.
    property bool startupHandled: false

    function applyStartupTemp(): void {
        if (root.startupHandled)
            return;
        root.startupHandled = true;
        if (persisted.temp > 0)
            Quickshell.execDetached(["sh", "-c", "pkill wlsunset 2>/dev/null; wlsunset -S 00:00 -s 00:01 -T 6501 -t " + persisted.temp]);
    }

    FileView {
        id: stateFile
        path: `${Quickshell.env("HOME")}/.local/state/caelestia/nightlight.json`
        printErrors: false

        onLoadFailed: error => {
            if (error === FileViewError.FileNotFound)
                stateFile.writeAdapter();
            // Nothing to restore either way once we know the load is done.
            root.applyStartupTemp();
        }
        onAdapterUpdated: stateFile.writeAdapter()

        adapter: JsonAdapter {
            id: persisted
            property int temp: -1
            // Fires once real data (including a value unchanged from -1,
            // if that's genuinely what was saved) is applied post-load.
            onTempChanged: root.applyStartupTemp()
        }
    }

    Component.onCompleted: {
        checkProc.running = true;
    }

    Process {
        id: checkProc

        command: ["sh", "-c", "command -v wlsunset >/dev/null 2>&1 && echo yes || echo no"]
        stdout: StdioCollector {
            onStreamFinished: root.available = text.trim() === "yes"
        }
    }
}
