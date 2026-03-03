import Testing
@testable import ServerPulse

@Suite("ByteFormatter Tests")
struct ByteFormatterTests {
    @Test func testFormatBytes() {
        #expect(ByteFormatter.format(UInt64(0)) == "0 B")
        #expect(ByteFormatter.format(UInt64(512)) == "512 B")
        #expect(ByteFormatter.format(UInt64(1024)) == "1.0 K")
        #expect(ByteFormatter.format(UInt64(1_048_576)) == "1.0 M")
        #expect(ByteFormatter.format(UInt64(1_073_741_824)) == "1.0 G")
        #expect(ByteFormatter.format(UInt64(1_099_511_627_776)) == "1.0 T")
    }

    @Test func testFormatLargeValues() {
        #expect(ByteFormatter.format(UInt64(150_000_000_000)) == "140 G")
    }

    @Test func testFormatRate() {
        let rate = ByteFormatter.formatRate(1_048_576)
        #expect(rate.hasSuffix("/s"))
    }

    @Test func testFormatShort() {
        #expect(ByteFormatter.formatShort(UInt64(0)) == "0 B")
        #expect(ByteFormatter.formatShort(UInt64(2048)) == "2 K")
    }
}

@Suite("TimeFormatter Tests")
struct TimeFormatterTests {
    @Test func testFormatUptime() {
        #expect(TimeFormatter.formatUptime(0) == "0m")
        #expect(TimeFormatter.formatUptime(3600) == "1h 0m")
        #expect(TimeFormatter.formatUptime(86400) == "1d 0h")
        #expect(TimeFormatter.formatUptime(90000) == "1d 1h")
        #expect(TimeFormatter.formatUptime(300) == "5m")
    }

    @Test func testFormatDuration() {
        #expect(TimeFormatter.formatDuration(0) == "00:00:00")
        #expect(TimeFormatter.formatDuration(3661) == "01:01:01")
        #expect(TimeFormatter.formatDuration(7200) == "02:00:00")
    }
}
