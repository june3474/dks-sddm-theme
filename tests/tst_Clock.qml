import QtQuick
import QtTest
import "../chili-dks/components"

TestCase {
    id: testCase
    name: "Clock"
    width: 400
    height: 200
    visible: true
    when: windowShown

    // 2024-11-24 was a Sunday.
    readonly property var sunday: new Date(2024, 10, 24, 13, 4, 59)

    Component {
        id: clockComponent
        Clock { }
    }

    function makeClock(date) {
        var clock = createTemporaryObject(clockComponent, testCase, { dateTime: date })
        verify(clock !== null, "Clock must load")
        return clock
    }

    // Depth-first search of the visual tree for a Text item.
    function findText(item, predicate) {
        if (item.text !== undefined && item.font !== undefined && predicate(item))
            return item
        for (var i = 0; i < item.children.length; ++i) {
            var found = findText(item.children[i], predicate)
            if (found)
                return found
        }
        return null
    }

    function timeText(clock) {
        var t = findText(clock, function(i) { return /^\d\d:\d\d$/.test(i.text) })
        verify(t !== null, "no hh:mm text")
        return t
    }

    function dateText(clock) {
        var d = findText(clock, function(i) { return !/^\d\d:\d\d$/.test(i.text) })
        verify(d !== null, "no date text")
        return d
    }

    function test_shows_hours_and_minutes() {
        compare(timeText(makeClock(sunday)).text, "13:04")
    }

    function test_date_is_the_long_locale_format() {
        // Not the short numeric form ("11/24/24"): weekday name, month name and the full year are spelled out.
        var text = dateText(makeClock(sunday)).text
        var locale = Qt.locale()
        verify(text.indexOf(locale.dayName(0)) >= 0, "weekday in '" + text + "'")
        verify(text.indexOf(locale.monthName(10)) >= 0, "month in '" + text + "'")
        verify(text.indexOf("2024") >= 0, "year in '" + text + "'")
    }

    function test_follows_dateTime() {
        var clock = makeClock(sunday)
        clock.dateTime = new Date(2025, 0, 2, 9, 30)
        compare(timeText(clock).text, "09:30")
        verify(dateText(clock).text.indexOf("2025") >= 0)
    }

    function test_ticks_on_its_own() {
        var clock = makeClock(sunday)
        tryVerify(function() { return Math.abs(clock.dateTime.getTime() - Date.now()) < 5000 }, 2000,
                  "dateTime should catch up with the current time")
    }

    function test_fonts_and_color_are_configurable_like_sddms_clock() {
        var clock = makeClock(sunday)
        clock.timeFont.pointSize = 33
        clock.timeFont.bold = true
        clock.dateFont.pointSize = 17
        clock.color = "red"
        var time = timeText(clock)
        var date = dateText(clock)
        compare(time.font.pointSize, 33)
        compare(time.font.bold, true)
        compare(date.font.pointSize, 17)
        compare(date.font.bold, false)
        compare(time.color.toString(), "#ff0000")
        compare(date.color.toString(), "#ff0000")
    }
}
