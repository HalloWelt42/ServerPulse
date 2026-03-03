import Testing
@testable import ServerPulse

@Suite("RingBuffer Tests")
struct RingBufferTests {
    @Test func testEmptyBuffer() {
        let buffer = RingBuffer<Int>(capacity: 5)
        #expect(buffer.elements.isEmpty)
        #expect(buffer.count == 0)
    }

    @Test func testAppendWithinCapacity() {
        var buffer = RingBuffer<Int>(capacity: 5)
        buffer.append(1)
        buffer.append(2)
        buffer.append(3)

        #expect(buffer.count == 3)
        #expect(buffer.elements == [1, 2, 3])
    }

    @Test func testAppendBeyondCapacity() {
        var buffer = RingBuffer<Int>(capacity: 3)
        buffer.append(1)
        buffer.append(2)
        buffer.append(3)
        buffer.append(4)
        buffer.append(5)

        #expect(buffer.count == 3)
        #expect(buffer.elements == [3, 4, 5])
    }

    @Test func testSingleCapacity() {
        var buffer = RingBuffer<String>(capacity: 1)
        buffer.append("a")
        #expect(buffer.elements == ["a"])

        buffer.append("b")
        #expect(buffer.elements == ["b"])
        #expect(buffer.count == 1)
    }

    @Test func testMetricDataPoints() {
        var buffer = RingBuffer<MetricDataPoint>(capacity: 5)
        for i in 0..<7 {
            buffer.append(MetricDataPoint(value: Double(i)))
        }

        #expect(buffer.count == 5)
        let values = buffer.elements.map(\.value)
        #expect(values == [2.0, 3.0, 4.0, 5.0, 6.0])
    }
}
