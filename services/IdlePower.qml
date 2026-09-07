pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io
import Caelestia.Config

// Reads/writes GlobalConfig.general.idle.timeouts directly — the same shell.json
// keys caelestia-idle.py used to edit from the outside — and always applies
// whichever of the AC/battery profiles below matches the current power state,
// the way power-idle-watch.sh did by shelling out to that script on every AC
// change.
//
// The AC/battery profile values themselves are file-backed (~/.local/state/
// idlepower/state.json), NOT PersistentProperties — PersistentProperties +
// reloadableId only survives Quickshell's live QML hot-reload, not a genuine
// process kill and restart (confirmed the hard way: even the upstream
// GameMode singleton's PersistentProperties-backed toggle failed to survive
// a real `pkill -9` + relaunch in testing). A real file survives an actual
// reboot, which is the whole point here.
Singleton {
    id: root

    readonly property string stateFile: Quickshell.env("HOME") + "/.local/state/idlepower/state.json"

    readonly property var defaults: ({
            acLock: 300,
            acDpms: 600,
            acSuspend: 1200,
            batLock: 180,
            batDpms: 300,
            batSuspend: 600,
            lastAcState: ""
        })

    // In-memory state, loaded from stateFile on startup and kept in sync
    // with it on every change. UI bindings (getProfileTimeout) read this
    // directly, so they update reactively once the async initial load
    // completes, same as any other Process-backed service in this codebase.
    property var state: root.defaults

    function loadState(): void {
        loadProc.running = true;
    }

    function saveState(): void {
        // Passed as plain argv (not shell-interpolated) so no quoting/
        // escaping concerns regardless of content.
        saveProc.command = ["sh", "-c", 'mkdir -p "$(dirname "$1")" && printf "%s" "$2" > "$1"', "--", root.stateFile, JSON.stringify(root.state)];
        saveProc.running = true;
    }

    Process {
        id: loadProc
        command: ["cat", root.stateFile]
        stdout: StdioCollector {
            onStreamFinished: {
                if (text.trim().length === 0)
                    return; // file doesn't exist yet — keep defaults
                try {
                    const parsed = JSON.parse(text);
                    root.state = Object.assign({}, root.defaults, parsed);
                } catch (e) {
                    console.warn("[IdlePower] failed to parse state file, keeping defaults:", e);
                }
            }
        }
    }

    Process {
        id: saveProc
    }

    // User-configurable AC/battery profiles (seconds, -1 for "off"). Every
    // field can be changed or turned off independently on the Power page —
    // whichever profile matches the current power state is always applied
    // automatically on AC change.
    function getProfileTimeout(profile: string, action: string): int {
        const key = (profile === "ac" ? "ac" : "bat") + action.charAt(0).toUpperCase() + action.slice(1);
        return root.state[key] ?? -1;
    }

    function setProfileTimeout(profile: string, action: string, val: int): void {
        const key = (profile === "ac" ? "ac" : "bat") + action.charAt(0).toUpperCase() + action.slice(1);
        root.state = Object.assign({}, root.state, {
            [key]: val
        });
        root.saveState();
        // If this is the currently-active power state, re-apply immediately
        // so a profile edit takes effect right away rather than waiting for
        // the next AC change.
        if (profile === root.state.lastAcState)
            root.applyProfile(profile);
    }

    function matches(t: var, action: string): bool {
        const a = t.idleAction;
        if (action === "lock")
            return a === "lock";
        if (action === "dpms")
            return a === "dpms off";
        if (action === "suspend") {
            // NOT Array.isArray(a) here — values coming back through QML's
            // Config property system can be array-*like* QJSValue wrappers
            // around a QVariantList that fail Array.isArray() despite
            // indexing/iterating fine. Duck-type on .length instead.
            if (!a || typeof a.length !== "number")
                return false;
            for (let i = 0; i < a.length; i++)
                if (a[i] === "suspend-then-hibernate")
                    return true;
            return false;
        }
        return false;
    }

    function applyProfile(name: string): void {
        const timeouts = (GlobalConfig.general.idle.timeouts ?? []).filter(t => !root.matches(t, "lock") && !root.matches(t, "dpms") && !root.matches(t, "suspend"));

        const lock = root.getProfileTimeout(name, "lock");
        const dpms = root.getProfileTimeout(name, "dpms");
        const suspend = root.getProfileTimeout(name, "suspend");

        if (lock !== -1)
            timeouts.push({
                timeout: lock,
                idleAction: "lock"
            });
        if (dpms !== -1)
            timeouts.push({
                timeout: dpms,
                idleAction: "dpms off",
                returnAction: "dpms on"
            });
        if (suspend !== -1)
            timeouts.push({
                timeout: suspend,
                idleAction: ["systemctl", "suspend-then-hibernate"]
            });

        GlobalConfig.general.idle.timeouts = timeouts;
    }

    // One-time cleanup for any duplicate entries left in shell.json from
    // earlier issues. Harmless no-op once the file is clean.
    function dedupeTimeouts(): void {
        const raw = GlobalConfig.general.idle.timeouts ?? [];
        const seen = new Set();
        const out = [];
        for (const t of raw) {
            const key = JSON.stringify(t);
            if (seen.has(key))
                continue;
            seen.add(key);
            out.push(t);
        }
        if (out.length !== raw.length)
            GlobalConfig.general.idle.timeouts = out;
    }

    function lockNow(): void {
        Quickshell.execDetached(["quickshell", "-c", "caelestia", "ipc", "call", "lock", "lock"]);
    }

    function checkAndApply(): void {
        // Coalesce bursts (startup + upower --monitor tends to emit several
        // lines right on connect for existing devices) into one actual
        // check, so we never read Config, compute a fresh timeouts array,
        // and write it twice before the first write has settled.
        checkDebounce.restart();
    }

    Timer {
        id: checkDebounce
        interval: 300
        onTriggered: acProc.running = true
    }

    Process {
        id: acProc

        // Same detection power-idle-watch.sh used: find the AC/ADP supply
        // and read its online flag.
        command: ["sh", "-c", "p=$(find /sys/class/power_supply -maxdepth 1 \\( -iname 'AC*' -o -iname 'ADP*' \\) | head -1); [ -n \"$p\" ] && [ -f \"$p/online\" ] && cat \"$p/online\" || echo unknown"]
        stdout: StdioCollector {
            onStreamFinished: {
                const val = text.trim();
                if (val !== "0" && val !== "1")
                    return;

                const newState = val === "1" ? "ac" : "battery";
                if (newState === root.state.lastAcState)
                    return;

                root.state = Object.assign({}, root.state, {
                    lastAcState: newState
                });
                root.saveState();
                root.applyProfile(newState);
            }
        }
    }

    // Delayed rather than run directly at startup, so the async loadState()
    // read (and its reactive update of root.state) has a chance to complete
    // before we compute/apply anything from it — and to stay clear of
    // whatever early-boot window caused dedupeTimeouts()'s GlobalConfig
    // write to get lost on the very first launches while debugging this.
    Timer {
        running: true
        interval: 3000
        onTriggered: {
            root.dedupeTimeouts();
            root.checkAndApply();
        }
    }

    Component.onCompleted: root.loadState()

    // Long-running upower monitor, same as power-idle-watch.sh's `upower
    // --monitor` loop — each event line triggers a re-check.
    Process {
        running: true
        command: ["upower", "--monitor"]
        stdout: SplitParser {
            onRead: () => root.checkAndApply()
        }
    }
}
