import QtQuick
import QtQuick.Controls
import QtTest
import "../chili-dks/components"

TestCase {
    id: testCase
    name: "KeyboardLayoutButton"
    width: 400
    height: 300
    visible: true
    when: windowShown

    // Stand-in for SDDM's KeyboardModel.
    QtObject {
        id: keyboard
        property var layouts: []
        property int currentLayout: 0
    }

    readonly property var twoLayouts: [
        { longName: "English (US)", shortName: "us" },
        { longName: "Deutsch", shortName: "de" }
    ]

    Component {
        id: buttonComponent
        KeyboardLayoutButton { x: 20; y: 20; implicitWidth: 40; implicitHeight: 20 }
    }

    // Qt 6 deprecates handlers that rely on implicitly injected signal parameters.
    function init() {
        failOnWarning(/Injection of parameters into signal handlers is deprecated/)
        keyboard.layouts = []
        keyboard.currentLayout = 0
    }

    function makeButton() {
        var button = createTemporaryObject(buttonComponent, testCase)
        verify(button !== null, "KeyboardLayoutButton must load")
        return button
    }

    function findMenu(button) {
        for (var i = 0; i < button.data.length; ++i)
            if (typeof button.data[i].itemAt === "function")
                return button.data[i]
        fail("button has no menu")
    }

    function test_hidden_unless_there_is_a_choice_of_layouts() {
        var button = makeButton()
        compare(button.visible, false)
        keyboard.layouts = [twoLayouts[0]]
        compare(button.visible, false)
        keyboard.layouts = twoLayouts
        compare(button.visible, true)
    }

    function test_click_opens_a_menu_below_the_button_listing_every_layout() {
        keyboard.layouts = twoLayouts
        var button = makeButton()
        var menu = findMenu(button)
        mouseClick(button)
        tryVerify(function() { return menu.opened })
        compare(menu.count, 2)
        compare(menu.itemAt(0).text, "English (US)")
        compare(menu.itemAt(1).text, "Deutsch")
        verify(menu.y >= button.height, "menu must not cover the button")
    }

    function test_choosing_a_layout_switches_the_keyboard() {
        keyboard.layouts = twoLayouts
        var button = makeButton()
        var menu = findMenu(button)
        mouseClick(button)
        tryVerify(function() { return menu.opened })
        mouseClick(menu.itemAt(1))
        compare(keyboard.currentLayout, 1)
        tryVerify(function() { return !menu.opened })
    }

    function test_menu_follows_layouts_added_later() {
        keyboard.layouts = twoLayouts
        var button = makeButton()
        var menu = findMenu(button)
        compare(menu.count, 2)
        keyboard.layouts = twoLayouts.concat([{ longName: "Français", shortName: "fr" }])
        compare(menu.count, 3)
        compare(menu.itemAt(2).text, "Français")
    }
}
