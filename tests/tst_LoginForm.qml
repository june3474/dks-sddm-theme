import QtQuick
import QtQuick.Controls
import QtTest
import "../chili-dks/components"

TestCase {
    id: testCase
    name: "LoginForm"
    width: 1280
    height: 800
    visible: true
    when: windowShown

    // Stand-ins for the globals and Main.qml ids the theme components rely on.
    property var config: ({ PasswordFieldOutlined: "false" }) // theme.conf values are strings
    QtObject { id: textConstants; property string password: "Password" }
    QtObject { id: sddm; signal loginFailed() }
    Item { id: root; width: testCase.width; height: testCase.height }
    ListModel {
        id: users
        ListElement { name: "alice"; realName: "Alice"; icon: "" }
        ListElement { name: "bob"; realName: "Bob"; icon: "" }
    }

    Component {
        // Mirrors Main.qml: the form lives in a StackView that owns the keyboard focus.
        id: stackComponent
        StackView {
            id: loginFormStack
            width: testCase.width
            height: testCase.height
            focus: true
            initialItem: LoginForm {
                userListModel: users
                userListCurrentIndex: 1
                usernameFontSize: 12
                usernameFontColor: "white"
                faceSize: 60
                actionItems: [ Item { implicitWidth: 40; implicitHeight: 40 } ]
            }
        }
    }

    Component {
        id: requestSpy
        SignalSpy { signalName: "loginRequest" }
    }

    // Qt 6 deprecates handlers that rely on implicitly injected signal parameters,
    // and reports layouts whose size feeds back into their own margins.
    function init() {
        failOnWarning(/Injection of parameters into signal handlers is deprecated/)
        failOnWarning(/polish\(\) loop/)
    }

    function makeStack() {
        var stack = createTemporaryObject(stackComponent, testCase)
        verify(stack !== null, "LoginForm must load inside a StackView")
        stack.forceActiveFocus()
        return stack
    }

    function typeText(text) {
        for (var i = 0; i < text.length; ++i)
            keyClick(text[i])
    }

    function passwordField() {
        var item = testCase.Window.activeFocusItem
        verify(item !== null && item.echoMode === TextInput.Password,
               "the password field must hold the keyboard focus")
        return item
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

    function loginButton(stack) {
        var button = findItem(stack, function(i) { return String(i.source).indexOf("login.svgz") >= 0 })
        verify(button !== null, "login button image")
        return button
    }

    function test_enter_submits_selected_user_and_typed_password() {
        var stack = makeStack()
        var spy = createTemporaryObject(requestSpy, testCase, { target: stack.currentItem })
        typeText("secret")
        keyClick(Qt.Key_Return)
        compare(spy.count, 1)
        compare(spy.signalArguments[0][0], "bob")
        compare(spy.signalArguments[0][1], "secret")
    }

    // Horizontal distance between the selected user's centre and the list's centre.
    function centreOffset(list) {
        var user = list.currentItem
        return user ? Math.round(user.mapToItem(list, user.width / 2, 0).x - list.width / 2) : NaN
    }

    function test_selected_user_stays_centred_in_the_list() {
        var stack = makeStack()
        var list = stack.currentItem.userList
        tryVerify(function() { return centreOffset(list) === 0 }, 2000, "preselected user centred")
        keyClick(Qt.Key_Left)
        compare(list.currentIndex, 0)
        tryVerify(function() { return centreOffset(list) === 0 }, 2000, "user after Left centred")
    }

    // The user list, the password prompt and the action items form one block centred in the StackView.
    function test_form_block_is_vertically_centred() {
        var stack = makeStack()
        var form = stack.currentItem
        var action = form.actionItems[0]
        tryVerify(function() {
            var top = form.userList.mapToItem(stack, 0, 0).y
            var bottom = action.mapToItem(stack, 0, action.height).y
            return Math.abs((top + bottom) / 2 - stack.height / 2) <= 1
        }, 2000, "block centred")
    }

    function test_escape_takes_focus_off_the_password_field() {
        var stack = makeStack()
        var field = passwordField()
        keyClick(Qt.Key_Escape)
        verify(testCase.Window.activeFocusItem !== field, "password field must give up focus")
        typeText("x")
        compare(field.text, "")
    }

    function test_left_and_right_switch_user_only_while_password_is_empty() {
        var stack = makeStack()
        var spy = createTemporaryObject(requestSpy, testCase, { target: stack.currentItem })
        function submitted(n, user) {
            keyClick(Qt.Key_Return)
            compare(spy.signalArguments[n][0], user, "submission " + n)
            compare(spy.signalArguments[n][1], "pw", "submission " + n)
        }
        function clearField() {
            keyClick(Qt.Key_End)
            keyClick(Qt.Key_Backspace)
            keyClick(Qt.Key_Backspace)
        }

        // Starts on the second user. With text typed, Left only moves the text cursor.
        typeText("pw")
        keyClick(Qt.Key_Left)
        submitted(0, "bob")

        // With an empty field, Left selects the previous user.
        clearField()
        keyClick(Qt.Key_Left)
        typeText("pw")
        submitted(1, "alice")

        // With text typed, Right only moves the text cursor.
        keyClick(Qt.Key_Right)
        submitted(2, "alice")

        // With an empty field, Right selects the next user.
        clearField()
        keyClick(Qt.Key_Right)
        typeText("pw")
        submitted(3, "bob")
    }

    function test_login_button_follows_password_presence() {
        var stack = makeStack()
        var button = loginButton(stack)
        compare(button.visible, false)
        typeText("x")
        tryCompare(button, "opacity", 0.75)
        keyClick(Qt.Key_Backspace)
        tryCompare(button, "visible", false)
    }

    function test_failed_login_selects_the_password_and_returns_focus() {
        var stack = makeStack()
        typeText("wrong")
        var field = passwordField()
        stack.forceActiveFocus() // focus wanders off the field
        sddm.loginFailed()
        compare(testCase.Window.activeFocusItem, field)
        compare(field.selectedText, "wrong")
    }
}
