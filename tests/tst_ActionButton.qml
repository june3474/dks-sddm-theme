import QtQuick
import QtQuick.Layouts
import QtTest
import "../chili-dks/components"

TestCase {
    id: testCase
    name: "ActionButton"
    width: 400
    height: 300
    visible: true
    when: windowShown

    QtObject { id: config }

    Component {
        id: buttonRow
        // Used inside a layout like in the theme.
        RowLayout {
            property alias button: button
            ActionButton {
                id: button
                text: "Reboot"
                iconSize: 30
            }
        }
    }

    Component {
        id: clickSpy
        SignalSpy { signalName: "clicked" }
    }

    function makeButton() {
        var row = createTemporaryObject(buttonRow, testCase, { width: 200, height: 100 })
        verify(row !== null, "ActionButton must load")
        return row.button
    }

    function test_mouse_click_emits_clicked() {
        var button = makeButton()
        var spy = createTemporaryObject(clickSpy, testCase, { target: button })
        mouseClick(button)
        compare(spy.count, 1)
    }

    function test_activation_keys_emit_clicked_when_focused() {
        var keys = [Qt.Key_Return, Qt.Key_Enter, Qt.Key_Space]
        for (var i = 0; i < keys.length; ++i) {
            var button = makeButton()
            var spy = createTemporaryObject(clickSpy, testCase, { target: button })
            button.forceActiveFocus()
            keyClick(keys[i])
            compare(spy.count, 1, "key " + keys[i])
        }
    }

    function test_dimmed_until_focused() {
        var button = makeButton()
        compare(button.opacity, 0.6)
        button.forceActiveFocus()
        compare(button.opacity, 1)
    }
}
