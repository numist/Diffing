/// An index that counts its offset from the start of its collection.
struct CountingIndex<Base : Comparable> : Equatable {
    /// The position in the underlying collection.
    let base: Base
    /// The offset from the start index of the collection or `nil` if `self` is
    /// the end index.
    let offset: Int?
}

extension CountingIndex : Comparable {
    static func <(lhs: CountingIndex, rhs: CountingIndex) -> Bool {
        return (lhs.base, lhs.offset ?? Int.max)
            < (rhs.base, rhs.offset ?? Int.max)
    }
}

/// A collection that counts the offset of its indices from its start index.
///
/// You can use `CountingIndexCollection` with algorithms on `Collection` to
/// calculate offsets of significance:
///
///     if let i = CountingIndexCollection("Café").index(of: "f") {
///         print(i.offset)
///     }
///     // Prints "2"
///
/// - Note: The offset of `endIndex` is `nil`
struct CountingIndexCollection<Base : Collection> {
    let base: Base

    init(_ base: Base) {
        self.base = base
    }
}

extension CountingIndexCollection : Collection {
    typealias Index = CountingIndex<Base.Index>
    typealias Element = Base.Element

    var startIndex: Index {
        return Index(base: base.startIndex, offset: base.isEmpty ? nil : 0)
    }

    var endIndex: Index {
        return Index(base: base.endIndex, offset: nil)
    }

    func index(after i: Index) -> Index {
        let next = base.index(after: i.base)
        return Index(
            base: next, offset: next == base.endIndex ? nil : i.offset! + 1)
    }

    subscript(position: Index) -> Element {
        return base[position.base]
    }
}
