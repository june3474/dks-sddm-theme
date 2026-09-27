import QtQuick
import QtTest
import "../chili-dks/components"

TestCase {
    id: testCase
    name: "Wallpaper"
    width: 400
    height: 300
    visible: true
    when: windowShown

    // config values come from theme.conf as strings, exactly like SDDM's ThemeConfig.
    property var configValues: ({})
    QtObject {
        id: config
        property var blur: testCase.configValues.blur
        property var recursiveBlurRadius: testCase.configValues.recursiveBlurRadius
        property var recursiveBlurLoops: testCase.configValues.recursiveBlurLoops
    }

    Item { id: container; focus: false }

    Component {
        id: wallpaper
        Wallpaper { width: 400; height: 300 }
    }

    function make(values) {
        configValues = values
        var w = createTemporaryObject(wallpaper, testCase)
        verify(w !== null, "Wallpaper must load")
        return w
    }

    // The blur item has no objectName; identify it by the properties it exposes.
    function findBlur(w) {
        for (var i = 0; i < w.children.length; ++i) {
            var c = w.children[i]
            if (c.radius !== undefined && c.loops !== undefined)
                return c
        }
        fail("Wallpaper has no blur item")
    }

    function test_blur_enabled_applies_string_settings_as_numbers() {
        var w = make({ blur: "true", recursiveBlurRadius: "15", recursiveBlurLoops: "4" })
        var blur = findBlur(w)
        compare(blur.radius, 15)
        compare(blur.loops, 4)
    }

    function test_blur_disabled_leaves_no_blur() {
        var w = make({ blur: "false", recursiveBlurRadius: "15", recursiveBlurLoops: "4" })
        var blur = findBlur(w)
        compare(blur.radius, 0)
        compare(blur.loops, 0)
    }

    function test_click_gives_container_focus() {
        var w = make({ blur: "false" })
        verify(!container.focus)
        mouseClick(w)
        verify(container.focus)
    }
}
