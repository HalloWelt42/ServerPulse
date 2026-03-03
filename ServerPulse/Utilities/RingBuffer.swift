import Foundation

struct RingBuffer<Element: Sendable>: Sendable {
    private var storage: [Element]
    private var head: Int = 0
    private var count_: Int = 0
    let capacity: Int

    init(capacity: Int) {
        self.capacity = capacity
        self.storage = []
        self.storage.reserveCapacity(capacity)
    }

    var count: Int { count_ }
    var isEmpty: Bool { count_ == 0 }

    mutating func append(_ element: Element) {
        if storage.count < capacity {
            storage.append(element)
        } else {
            storage[head] = element
        }
        head = (head + 1) % capacity
        count_ = min(count_ + 1, capacity)
    }

    var elements: [Element] {
        guard !isEmpty else { return [] }
        if storage.count < capacity {
            return Array(storage)
        }
        return Array(storage[head...]) + Array(storage[..<head])
    }

    var last: Element? {
        guard !isEmpty else { return nil }
        let index = (head - 1 + capacity) % capacity
        return storage.indices.contains(index) ? storage[index] : nil
    }

    mutating func removeAll() {
        storage.removeAll(keepingCapacity: true)
        head = 0
        count_ = 0
    }
}
