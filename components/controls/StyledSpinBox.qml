import QtQuick
import QtQuick.Templates as T
import Caelestia.Config
import qs.components
import qs.services

// Was a DoubleSpinBox (QtQuick.Templates). That type does not exist in any
// released Qt6 -- confirmed against Qt's own repo, it's only present on
// Qt's unreleased dev branch, not 6.9, not even the (at time of writing)
// unreleased 6.10 branch. Rewritten as a thin wrapper around the classic
// integer T.SpinBox using the standard scaled-integer trick for decimal
// support, so real (fractional) from/to/stepSize/value keep working exactly
// as before for every caller (StepperRow.qml etc.) -- same public property
// names, same signal, same visuals. Only the internal implementation changed.
Item {
    id: root

    property real value: 0
    property real from: 0
    property real to: 99
    property real stepSize: 1
    property int decimals: stepSize < 1 ? Math.max(1, Math.ceil(-Math.log10(stepSize))) : 0
    property bool editable: true
    property int repeatRate: 400
    property int repeatDecay: 50
    property int cLayer: 1
    property var locale: Qt.locale()

    signal valueModified

    readonly property real scaleFactor: Math.pow(10, decimals)

    function textFromValue(v: real, loc): string {
        return Number(v).toLocaleString(loc, "f", decimals);
    }

    function valueFromText(text: string, loc): real {
        return Number.fromLocaleString(loc, text);
    }

    function increase(): void {
        let newValue = Math.min(to, value + stepSize);
        newValue = Math.round(newValue * scaleFactor) / scaleFactor;
        value = newValue;
        valueModified();
    }

    function decrease(): void {
        let newValue = Math.max(from, value - stepSize);
        newValue = Math.round(newValue * scaleFactor) / scaleFactor;
        value = newValue;
        valueModified();
    }

    implicitWidth: spin.implicitWidth
    implicitHeight: spin.implicitHeight

    T.SpinBox {
        id: spin

        anchors.fill: parent

        from: Math.round(root.from * root.scaleFactor)
        to: Math.round(root.to * root.scaleFactor)
        stepSize: Math.max(1, Math.round(root.stepSize * root.scaleFactor))
        value: Math.round(root.value * root.scaleFactor)
        editable: root.editable
        spacing: Tokens.spacing.small

        textFromValue: v => root.textFromValue(v / root.scaleFactor, spin.locale)
        valueFromText: (text, loc) => Math.round(root.valueFromText(text, loc) * root.scaleFactor)

        onValueModified: {
            root.value = spin.value / root.scaleFactor;
            root.valueModified();
        }

        leftPadding: up.indicator.implicitWidth + Tokens.spacing.extraSmall / 2
        rightPadding: down.indicator.implicitWidth + Tokens.spacing.extraSmall / 2

        contentItem: TextFieldBase {
            text: spin.textFromValue(spin.value, spin.locale)

            readOnly: !spin.editable
            validator: spin.validator
            inputMethodHints: Qt.ImhFormattedNumbersOnly

            leftPadding: Tokens.padding.medium
            rightPadding: Tokens.padding.medium

            implicitWidth: 65
            horizontalAlignment: Text.AlignHCenter

            background: StyledRect {
                radius: Tokens.rounding.extraSmall
                color: Colours.layer(Colours.palette.m3surfaceContainerHighest, root.cLayer)
            }
        }

        down.indicator: IconButton {
            id: downButton

            topRightRadius: pressed ? Tokens.rounding.small : Tokens.rounding.extraSmall
            bottomRightRadius: pressed ? Tokens.rounding.small : Tokens.rounding.extraSmall

            icon: "remove"
            disabledColour: Qt.alpha(Colours.palette.m3surfaceContainerHighest, 0.4)
            color: disabled ? disabledColour : Colours.layer(Colours.palette.m3surfaceContainerHighest, root.cLayer)
            type: IconButton.Text
            padding: Tokens.padding.extraSmall
            isRound: true
            label.anchors.horizontalCenterOffset: pressed ? 0 : 2
            disabled: !enabled

            Behavior on topRightRadius {
                Anim {
                    type: Anim.DefaultEffects
                }
            }

            Behavior on bottomRightRadius {
                Anim {
                    type: Anim.DefaultEffects
                }
            }

            Behavior on label.anchors.horizontalCenterOffset {
                Anim {
                    type: Anim.DefaultEffects
                }
            }
        }

        up.indicator: IconButton {
            id: upButton

            anchors.right: parent.right

            topLeftRadius: pressed ? Tokens.rounding.small : Tokens.rounding.extraSmall
            bottomLeftRadius: pressed ? Tokens.rounding.small : Tokens.rounding.extraSmall

            icon: "add"
            disabledColour: Qt.alpha(Colours.palette.m3surfaceContainerHighest, 0.4)
            color: disabled ? disabledColour : Colours.layer(Colours.palette.m3surfaceContainerHighest, root.cLayer)
            type: IconButton.Text
            padding: Tokens.padding.extraSmall
            isRound: true
            label.anchors.horizontalCenterOffset: pressed ? 0 : -2
            disabled: !enabled

            Behavior on topLeftRadius {
                Anim {
                    type: Anim.DefaultEffects
                }
            }

            Behavior on bottomLeftRadius {
                Anim {
                    type: Anim.DefaultEffects
                }
            }

            Behavior on label.anchors.horizontalCenterOffset {
                Anim {
                    type: Anim.DefaultEffects
                }
            }
        }

        Timer {
            id: timer

            running: upButton.pressed || downButton.pressed
            onRunningChanged: {
                if (!running)
                    interval = root.repeatRate;
            }

            interval: root.repeatRate
            repeat: true
            triggeredOnStart: true
            onTriggered: {
                if (upButton.pressed)
                    root.increase();
                else if (downButton.pressed)
                    root.decrease();
                if (interval > root.repeatDecay)
                    interval -= root.repeatDecay;
            }
        }
    }
}
