pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io

// Wraps wlr-randr. river/wlroots has no client-facing protocol for reading or
// setting output mode/scale/transform/position (same category of gap as the
// missing foreign-toplevel/ext-workspace protocols), so this shells out the
// same way quicksettings.sh did — just cached in a singleton instead of
// re-parsed by fuzzel each time, and with its own restore-on-start instead of
// relying on quicksettings-restore.sh.
Singleton {
    id: root

    // Each entry: { name, modes: [{res, hz}], currentMode, currentHz, scale,
    // transform, adaptive, position }
    property list<var> outputs: []
    property bool ready: false

    function outputFor(name: string): var {
        return root.outputs.find(o => o.name === name) ?? null;
    }

    function refresh(): void {
        listProc.running = true;
    }

    function setMode(name: string, res: string, hz: string): void {
        Quickshell.execDetached(["wlr-randr", "--output", name, "--mode", `${res}@${hz}`]);
        savePersisted(name, {
            mode: `${res}@${hz}`
        });
        settleTimer.restart();
    }

    function setScale(name: string, scale: real): void {
        Quickshell.execDetached(["wlr-randr", "--output", name, "--scale", String(scale)]);
        savePersisted(name, {
            scale
        });
        settleTimer.restart();
    }

    function setTransform(name: string, transform: string): void {
        Quickshell.execDetached(["wlr-randr", "--output", name, "--transform", transform]);
        savePersisted(name, {
            transform
        });
        settleTimer.restart();
    }

    function setAdaptive(name: string, enabled: bool): void {
        Quickshell.execDetached(["wlr-randr", "--output", name, "--adaptive-sync", enabled ? "enabled" : "disabled"]);
        savePersisted(name, {
            adaptive: enabled ? "enabled" : "disabled"
        });
        settleTimer.restart();
    }

    function setPosition(name: string, pos: string): void {
        Quickshell.execDetached(["wlr-randr", "--output", name, "--pos", pos]);
        savePersisted(name, {
            position: pos
        });
        settleTimer.restart();
    }

    // Mirrors quicksettings.sh's arrange_displays_menu: mode is one of
    // "mirror", "extend-right", "extend-above". Primary is eDP-1 if present,
    // else the first output.
    function arrange(mode: string): void {
        const outs = root.outputs;
        if (outs.length < 2)
            return;

        const primary = outs.find(o => o.name === "eDP-1") ?? outs[0];
        const others = outs.filter(o => o !== primary);

        setPosition(primary.name, "0,0");

        if (mode === "mirror") {
            for (const o of others)
                setPosition(o.name, "0,0");
            return;
        }

        if (mode === "extend-right") {
            let offset = dimsOf(primary).w;
            for (const o of others) {
                setPosition(o.name, `${offset},0`);
                offset += dimsOf(o).w;
            }
            return;
        }

        if (mode === "extend-above") {
            for (const o of others)
                setPosition(o.name, `0,-${dimsOf(o).h}`);
        }
    }

    function dimsOf(output: var): var {
        const res = output.currentMode || "0x0";
        const [w, h] = res.split("x").map(Number);
        return {
            w: w || 0,
            h: h || 0
        };
    }

    // ---- persistence (replaces quicksettings-restore.sh) ----

    function savePersisted(name: string, patch: var): void {
        const all = Object.assign({}, persisted.byOutput);
        all[name] = Object.assign({}, all[name] ?? {}, patch);
        persisted.byOutput = all;
    }

    PersistentProperties {
        id: persisted

        property var byOutput: ({})

        reloadableId: "wlrRandrState"
    }

    function applyPersisted(): void {
        for (const o of root.outputs) {
            const saved = persisted.byOutput[o.name];
            if (!saved)
                continue;
            if (saved.mode && saved.mode !== `${o.currentMode}@${o.currentHz}`) {
                const [res, hz] = saved.mode.split("@");
                Quickshell.execDetached(["wlr-randr", "--output", o.name, "--mode", saved.mode]);
            }
            if (saved.scale !== undefined && Math.abs(saved.scale - o.scale) > 0.001)
                Quickshell.execDetached(["wlr-randr", "--output", o.name, "--scale", String(saved.scale)]);
            if (saved.transform && saved.transform !== o.transform)
                Quickshell.execDetached(["wlr-randr", "--output", o.name, "--transform", saved.transform]);
            if (saved.adaptive && saved.adaptive !== o.adaptive)
                Quickshell.execDetached(["wlr-randr", "--output", o.name, "--adaptive-sync", saved.adaptive]);
            if (saved.position)
                Quickshell.execDetached(["wlr-randr", "--output", o.name, "--pos", saved.position]);
        }
    }

    // Retry until wlr-randr actually reports outputs (mirrors the wait loop
    // quicksettings-restore.sh used for the same reason: this can run before
    // the compositor has finished enumerating outputs).
    property int startupTries: 0

    Timer {
        id: startupTimer
        interval: 250
        repeat: true
        running: !root.ready
        onTriggered: {
            root.startupTries++;
            root.refresh();
            if (root.startupTries > 20)
                running = false;
        }
    }

    // Debounces re-reads after we just issued a set*() call, so the UI
    // reflects the applied value without hammering wlr-randr.
    Timer {
        id: settleTimer
        interval: 300
        onTriggered: root.refresh()
    }

    Process {
        id: listProc

        command: ["wlr-randr"]
        stdout: StdioCollector {
            onStreamFinished: {
                root.outputs = root.parse(text);
                if (!root.ready && root.outputs.length > 0) {
                    root.ready = true;
                    startupTimer.running = false;
                    root.applyPersisted();
                }
            }
        }
    }

    function parse(text: string): var {
        const lines = text.split("\n");
        const outputs = [];
        let cur = null;

        for (const raw of lines) {
            if (raw.length === 0)
                continue;

            if (!/^\s/.test(raw)) {
                const name = raw.trim().split(" ")[0];
                cur = {
                    name,
                    modes: [],
                    currentMode: "",
                    currentHz: "",
                    scale: 1,
                    transform: "normal",
                    adaptive: "disabled",
                    position: "0,0"
                };
                outputs.push(cur);
                continue;
            }

            if (!cur)
                continue;

            const line = raw.trim();
            let m;

            if ((m = line.match(/^([0-9]+x[0-9]+) px, ([0-9.]+) Hz\s*(\([^)]*\))?/))) {
                cur.modes.push({
                    res: m[1],
                    hz: m[2]
                });
                if (m[3] && m[3].includes("current")) {
                    cur.currentMode = m[1];
                    cur.currentHz = m[2];
                }
            } else if ((m = line.match(/^Position:\s*(.+)/))) {
                cur.position = m[1];
            } else if ((m = line.match(/^Transform:\s*(\S+)/))) {
                cur.transform = m[1];
            } else if ((m = line.match(/^Scale:\s*([0-9.]+)/))) {
                cur.scale = parseFloat(m[1]);
            } else if ((m = line.match(/^Adaptive Sync:\s*(\w+)/))) {
                cur.adaptive = m[1];
            }
        }

        return outputs;
    }
}
