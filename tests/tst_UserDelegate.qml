import QtQuick
import QtTest
import "../chili-dks/components"

TestCase {
    id: testCase
    name: "UserDelegate"
    width: 200
    height: 260
    visible: true
    when: windowShown

    Component {
        id: list
        ListView {
            width: 200
            height: 260
            model: ListModel { ListElement { name: "dks" } }
            delegate: UserDelegate {
                width: 200
                height: 260
                name: model.name
                faceSize: 100
                avatarPath: Qt.resolvedUrl("fixtures/avatar.svg")
                usernameFontSize: 10
                usernameFontColor: "white"
            }
        }
    }

    function makeDelegate() {
        var view = createTemporaryObject(list, testCase)
        verify(view !== null, "UserDelegate must load")
        var d = view.itemAtIndex(0)
        verify(d !== null)
        return d
    }

    function test_current_user_is_opaque_and_others_dimmed() {
        var d = makeDelegate()
        d.isCurrent = true
        tryCompare(d, "opacity", 1.0)
        d.isCurrent = false
        tryCompare(d, "opacity", 0.3)
    }

    function test_avatar_is_masked_to_the_mask_shape() {
        if (GraphicsInfo.api === GraphicsInfo.Software)
            skip("the software renderer does not draw ShaderEffect; run with a GPU platform, e.g. QT_QPA_PLATFORM=xcb")
        var d = makeDelegate()
        wait(300) // let images load and the effect render
        var img = grabImage(d)
        // The avatar is solid red and the mask image itself is a grey disc, so a working
        // OpacityMask shows red at the centre (grey would mean the avatar is missing)
        // and leaves the corner of the square face empty (window background, not red).
        var cx = Math.round(d.width / 2)
        var cy = 50 // vertical centre of the 100px face
        verify(img.red(cx, cy) > 200, "red " + img.red(cx, cy))
        verify(img.green(cx, cy) < 120, "green " + img.green(cx, cy))
        verify(img.blue(cx, cy) < 120, "blue " + img.blue(cx, cy))
        verify(img.green(cx - 49, 1) > 200, "corner green " + img.green(cx - 49, 1))
    }
}
