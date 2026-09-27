import QtQuick
import QtQuick.Controls
import QtTest
import "../chili-dks/components"

TestCase {
    id: testCase
    name: "SessionMenu"
    width: 400
    height: 300
    visible: true
    when: windowShown

    // Stand-in for SDDM's SessionModel.
    ListModel {
        id: sessionModel
        property int lastIndex: 1
    }

    Component {
        // Bottom-left like the theme's footer, so the popup has to open upwards.
        id: menuComponent
        SessionMenu {
            x: 10
            y: testCase.height - height - 10
            rootFontSize: 12
            rootFontColor: "white"
        }
    }

    // Qt 6 deprecates injected handler parameters; a null session entry must not raise TypeErrors.
    function init() {
        failOnWarning(/Injection of parameters into signal handlers is deprecated/)
        failOnWarning(/TypeError|Cannot read/)
        sessionModel.clear()
        sessionModel.lastIndex = 1
    }

    function setSessions(names) {
        for (var i = 0; i < names.length; ++i)
            sessionModel.append({ name: names[i] })
    }

    function makeMenu() {
        var button = createTemporaryObject(menuComponent, testCase)
        verify(button !== null, "SessionMenu must load")
        return button
    }

    function findMenu(button) {
        for (var i = 0; i < button.data.length; ++i)
            if (typeof button.data[i].itemAt === "function")
                return button.data[i]
        fail("button has no menu")
    }

    // Depth-first search of the visual tree.
    function findItem(item, predicate) {
        if (predicate(item))
            return item
        for (var i = 0; i < item.children.length; ++i) {
            var found = findItem(item.children[i], predicate)
            if (found)
                return found
        }
        return null
    }

    function shownLabel(button) {
        return findItem(button, function(i) { return i.text !== undefined && i.visible && i.text !== "" })
    }

    function test_hidden_unless_there_is_a_choice_of_sessions() {
        var button = makeMenu()
        compare(button.visible, false)
        setSessions(["Xfce"])
        compare(button.visible, false)
        setSessions(["Plasma"])
        compare(button.visible, true)
    }

    function test_shows_the_last_used_session() {
        setSessions(["Xfce", "Plasma", "Kodi"])
        var button = makeMenu()
        compare(button.currentIndex, 1)
        compare(shownLabel(button).text, "Plasma")
    }

    function test_click_opens_menu_above_the_button_listing_every_session() {
        setSessions(["Xfce", "Plasma", "Kodi"])
        var button = makeMenu()
        var menu = findMenu(button)
        mouseClick(button)
        tryVerify(function() { return menu.opened })
        compare(menu.count, 3)
        compare(menu.itemAt(0).text, "Xfce")
        compare(menu.itemAt(2).text, "Kodi")
        // Qt keeps popups inside the window, so check the outcome that matters here:
        // the menu sits above the button instead of covering it.
        var menuBottom = button.mapToItem(null, menu.x, menu.y + menu.height).y
        var buttonTop = button.mapToItem(null, 0, 0).y
        verify(menuBottom <= buttonTop + 1, "menu bottom " + menuBottom + " overlaps button top " + buttonTop)
    }

    function test_choosing_a_session_updates_the_selection_and_label() {
        setSessions(["Xfce", "Plasma", "Kodi"])
        var button = makeMenu()
        var menu = findMenu(button)
        mouseClick(button)
        tryVerify(function() { return menu.opened })
        mouseClick(menu.itemAt(2))
        compare(button.currentIndex, 2)
        compare(shownLabel(button).text, "Kodi")
    }
}
