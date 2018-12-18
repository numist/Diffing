/// A collection of changes between a source and target collection.
///
/// It can be used to traverse the [longest common subsequence][lcs] of
/// source and target:
///
///     let changes = CollectionChanges(from: source, to target)
///     for case let .match(s, t) in changes {
///         // use `s`, `t`
///     }
///
/// It can also be used to traverse the [shortest edit script][ses] of
/// remove and insert operations:
///
///     let changes = CollectionChanges(from: source, to target)
///     for c in changes {
///         switch c {
///         case let .removed(s):
///             // use `s`
///         case let .inserted(t):
///             // use `t`
///         case .matched: continue
///         }
///     }
///
/// [lcs]: http://en.wikipedia.org/wiki/Longest_common_subsequence_problem
/// [ses]: http://en.wikipedia.org/wiki/Edit_distance
///
/// - Note: `CollectionChanges` holds a reference to state used to run the
///         difference algorithm, which can be exponentially larger than the
///         changes themselves.
struct CollectionChanges<
    SourceIndex : Comparable, TargetIndex : Comparable
> {
    typealias Endpoint = (x: SourceIndex, y: TargetIndex)

    /// An encoding of change elements as an array of index pairs stored in
    /// `pathStorage[pathStartIndex...]`.
    ///
    /// This encoding allows the same storage to be used to run the difference
    /// algorithm, report the result, and repeat in place using
    /// `formChanges`.
    ///
    /// The collection of changes between XABCD and XYCD is:
    ///
    ///     [.match(0..<1, 0..<1), .remove(1..<3), .insert(1..<2),
    ///      .match(3..<5, 2..<4)]
    ///
    /// Which gets encoded as:
    ///
    ///     [(0, 0), (1, 1), (3, 1), (3, 2), (5, 4)]
    ///
    /// You can visualize it as a two-dimensional path composed of remove
    /// (horizontal), insert (vertical), and match (diagonal) segments:
    ///
    ///       X A B C D
    ///     X \ _ _
    ///     Y      |
    ///     C       \
    ///     D         \
    ///
    private var pathStorage: [Endpoint]

    /// The index in `pathStorage` of the first segment in the difference path.
    private var pathStartIndex: Int

    /// Creates a collection of changes from a difference path.
    fileprivate init(
        pathStorage: [Endpoint], pathStartIndex: Int
    ) {
        self.pathStorage = pathStorage
        self.pathStartIndex = pathStartIndex
    }

    /// Creates an empty collection of changes, i.e. the changes between two
    /// empty collections.
    init() {
        self.pathStorage = []
        self.pathStartIndex = 0
    }
}

extension CollectionChanges {
    /// A range of elements removed from the source, inserted in the target, or
    /// that the source and target have in common.
    enum Element {
        case removed(Range<SourceIndex>)
        case inserted(Range<TargetIndex>)
        case matched(Range<SourceIndex>, Range<TargetIndex>)
    }
}

extension CollectionChanges : RandomAccessCollection {
    typealias Index = Int

    var startIndex: Index {
        return 0
    }

    var endIndex: Index {
        return Swift.max(0, pathStorage.endIndex - pathStartIndex - 1)
    }

    func index(after i: Index) -> Index {
        return i + 1
    }

    func index(before i: Index) -> Index {
        return i - 1
    }

    subscript(position: Index) -> Element {
        precondition((startIndex..<endIndex).contains(position))

        let current = pathStorage[position + pathStartIndex]
        let next = pathStorage[position + pathStartIndex + 1]

        if current.x != next.x && current.y != next.y {
            return .matched(current.x..<next.x, current.y..<next.y)
        } else if current.x != next.x {
            return .removed(current.x..<next.x)
        } else { // current.y != next.y
            return .inserted(current.y..<next.y)
        }
    }
}

extension CollectionChanges : CustomStringConvertible {
    var description: String {
        return String(describing: Array(self))
    }
}

extension CollectionChanges {
    /// Creates the collection of changes between `source` and `target`.
    ///
    /// - Runtime: O(*n* * *d*), where *n* is `source.count + target.count` and
    ///   *d* is the minimal number of inserted and removed elements.
    /// - Space: O(*d* * *d*), where *d* is the minimal number of inserted and
    ///   removed elements.
    init<Source : OrderedCollection, Target : OrderedCollection>(
        from source: Source, to target: Target, by areEquivalent: (Source.Element, Target.Element) -> Bool
    ) where
        Source.Element == Target.Element,
        Source.Index == SourceIndex,
        Target.Index == TargetIndex
    {
        self.init()
        formChanges(from: source, to: target, by: areEquivalent)
    }

    /// Replaces `self` with the collection of changes between `source`
    /// and `target`.
    ///
    /// - Runtime: O(*n* * *d*), where *n* is `source.count + target.count` and
    ///   *d* is the minimal number of inserted and removed elements.
    /// - Space: O(*d*²), where *d* is the minimal number of inserted and
    ///   removed elements.
    mutating func formChanges<
        Source : OrderedCollection, Target : OrderedCollection
    >(
        from source: Source, to target: Target, by areEquivalent: (Source.Element, Target.Element) -> Bool
    ) where
        Source.Element == Target.Element,
        Source.Index == SourceIndex,
        Target.Index == TargetIndex
    {
        let pathStart = (x: source.startIndex, y: target.startIndex)
        let pathEnd = (x: source.endIndex, y: target.endIndex)
        let matches = source.commonPrefix(with: target, by: areEquivalent)
        let (x, y) = (matches.0.endIndex, matches.1.endIndex)

        if pathStart == pathEnd {
            pathStorage.removeAll(keepingCapacity: true)
            pathStartIndex = 0
        } else if x == pathEnd.x || y == pathEnd.y {
            pathStorage.removeAll(keepingCapacity: true)
            pathStorage.append(pathStart)
            if pathStart != (x, y) && pathEnd != (x, y) {
                pathStorage.append((x, y))
            }
            pathStorage.append(pathEnd)
            pathStartIndex = 0
        } else {
            formChangesCore(from: source, to: target, x: x, y: y, by: areEquivalent)
        }
    }

    /// The core difference algorithm.
    ///
    /// - Precondition: There is at least one difference between `a` and `b`
    /// - Runtime: O(*n* * *d*), where *n* is `a.count + b.count` and
    ///   *d* is the number of inserts and removes.
    /// - Space: O(*d* * *d*), where *d* is the number of inserts and removes.
    @inline(__always)
    private mutating func formChangesCore<
        Source : OrderedCollection, Target : OrderedCollection
    >(
        from a: Source,
        to b: Target,
        x: Source.Index,
        y: Target.Index,
        by areEquivalent: (Source.Element, Target.Element) -> Bool
    ) where
        Source.Element == Target.Element,
        Source.Index == SourceIndex,
        Target.Index == TargetIndex
    {
        // Written to correspond, as closely as possible, to the psuedocode in
        // Myers, E. "An O(ND) Difference Algorithm and Its Variations".
        //
        // See "FIGURE 2: The Greedy LCS/SES Algorithm" on p. 6 of the [paper].
        //
        // Note the following differences from the psuedocode in FIGURE 2:
        //
        // 1. FIGURE 2 relies on both *A* and *B* being Arrays. In a generic
        //    context, it isn't true that *y = x - k*, as *x*, *y*, *k* could
        //    all be different types, so we store both *x* and *y* in *V*.
        // 2. FIGURE 2 only reports the length of the LCS/SES. Reporting a
        //    solution path requires storing a copy of *V* (the search frontier)
        //    after each iteration of the outer loop.
        // 3. FIGURE 2 stops the search after *MAX* iterations. We run the loop
        //    until a solution is found. We also guard against incrementing past
        //    the end of *A* and *B*, both to satisfy the termination condition
        //    and because that would violate preconditions on collection.
        //
        // [paper]: http://www.xmailserver.org/diff2.pdf
        var (x, y) = (x, y)
        let (n, m) = (a.endIndex, b.endIndex)

        var v = SearchState<Source.Index, Target.Index>(consuming: &pathStorage)

        v.appendFrontier(repeating: (x, y))
        var d = 1
        var delta = 0
        outer: while true {
            v.appendFrontier(repeating: (n, m))
            for k in stride(from: -d, through: d, by: 2) {
                if k == -d || (k != d && v[d - 1, k - 1].x < v[d - 1, k + 1].x) {
                    (x, y) = v[d - 1, k + 1]
                    if y != m { b.formIndex(after: &y) }
                } else {
                    (x, y) = v[d - 1, k - 1]
                    if x != n { a.formIndex(after: &x) }
                }

                let matches = a[x..<n].commonPrefix(with: b[y..<m], by: areEquivalent)
                (x, y) = (matches.0.endIndex, matches.1.endIndex)
                v[d, k] = (x, y)

                if x == n && y == m {
                    delta = k
                    break outer
                }
            }
            d += 1
        }

        self = v.removeCollectionChanges(a: a, b: b, d: d, delta: delta)
    }
}

/// The search paths being explored.
fileprivate struct SearchState<
    SourceIndex : Comparable, TargetIndex : Comparable
> {
    typealias Endpoint = (x: SourceIndex, y: TargetIndex)

    /// The search frontier for each iteration.
    ///
    /// The nth iteration of the core algorithm requires storing n + 1 search
    /// path endpoints. Thus, the shape of the storage required is a triangle.
    private var endpoints = LowerTriangularMatrix<Endpoint>()

    /// Creates an instance, taking the capacity of `storage` for itself.
    ///
    /// - Postcondition: `storage` is empty.
    init(consuming storage: inout [Endpoint]) {
        storage.removeAll(keepingCapacity: true)
        swap(&storage, &endpoints.storage)
    }

    /// Returns the endpoint of the search frontier for iteration `d` on
    /// diagonal `k`.
    subscript(d: Int, k: Int) -> Endpoint {
        get {
            assert((-d...d).contains(k))
            assert((d + k) % 2 == 0)
            return endpoints[d, (d + k) / 2]
        }
        set {
            assert((-d...d).contains(k))
            assert((d + k) % 2 == 0)
            endpoints[d, (d + k) / 2] = newValue
        }
    }

    /// Adds endpoints initialized to `repeatedValue` for the search frontier of
    /// the next iteration.
    mutating func appendFrontier(repeating repeatedValue: Endpoint) {
        endpoints.appendRow(repeating: repeatedValue)
    }
}

extension SearchState {
    /// Removes and returns `CollectionChanges`, leaving `SearchState` empty.
    ///
    /// - Precondition: There is at least one difference between `a` and `b`
    mutating func removeCollectionChanges<
        Source : OrderedCollection, Target : OrderedCollection
    >(
        a: Source, b: Target, d: Int, delta: Int
    ) -> CollectionChanges<Source.Index, Target.Index>
        where Source.Index == SourceIndex, Target.Index == TargetIndex
    {
        // Calculating the difference path is very similar to running the core
        // algorithm in reverse:
        //
        //     var k = delta
        //     for d in (1...d).reversed() {
        //         if k == -d || (k != d && self[d - 1, k - 1].x < self[d - 1, k + 1].x) {
        //             // insert of self[d - 1, k + 1].y
        //             k += 1
        //         } else {
        //             // remove of self[d - 1, k - 1].x
        //             k -= 1
        //         }
        //     }
        //
        // It is more complicated below because:
        //
        // 1. We want to include segments for matches
        // 2. We want to coallesce consecutive like segments
        // 3. We don't want to allocate, so we're overwriting the elements of
        //    endpoints.storage we've finished reading.

        let pathStart = (a.startIndex, b.startIndex)
        let pathEnd = (a.endIndex, b.endIndex)

        // `endpoints.storage` may need space for an additional element in order
        // to store the difference path when `d == 1`.
        //
        // `endpoints.storage` has `(d + 1) * (d + 2) / 2` elements stored,
        // but a difference path requires up to `2 + d * 2` elements[^1].
        //
        // If `d == 1`:
        //
        //     (1 + 1) * (1 + 2) / 2 < 2 + 1 * 2
        //                         3 < 4
        //
        // `d == 1` is the only special case because:
        //
        // - It's a precondition that `d > 0`.
        // - Once `d >= 2` `endpoints.storage` will have sufficient space:
        //
        //       (d + 1) * (d + 2) / 2 = 2 + d * 2
        //        d * d - d - 2 = 0
        //       (d - 2) * (d + 1) = 0
        //        d = 2; d = -1
        //
        // [1]: An endpoint for every remove, insert, and match segment. (Recall
        // *d* is the minimal number of inserted and removed elements). If there
        // are no consecutive removes or inserts and every remove or insert is
        // sandwiched between matches, the path will need `2 + d * 2` elements.
        assert(d > 0, "Must be at least one difference between `a` and `b`")
        if d == 1 {
            endpoints.storage.append(pathEnd)
        }

        var i = endpoints.storage.endIndex - 1
        // `isInsertion` tracks whether the element at `endpoints.storage[i]`
        // is an insertion (`true`), a removal (`false`), or a match (`nil`).
        var isInsertion: Bool? = nil
        var k = delta
        endpoints.storage[i] = pathEnd
        for d in (1...d).reversed() {
            if k == -d || (k != d && self[d - 1, k - 1].x < self[d - 1, k + 1].x) {
                let (x, y) = self[d - 1, k + 1]

                // There was match before this insert, so add a segment.
                if x != endpoints.storage[i].x {
                    i -= 1; endpoints.storage[i] = (x, b.index(after: y))
                    isInsertion = nil
                }

                // If the previous segment is also an insert, overwrite it.
                if isInsertion != .some(true) { i -= 1 }
                endpoints.storage[i] = (x, y)

                isInsertion = true
                k += 1
            } else {
                let (x, y) = self[d - 1, k - 1]

                // There was a match before this remove, so add a segment.
                if y != endpoints.storage[i].y {
                    i -= 1; endpoints.storage[i] = (a.index(after: x), y)
                    isInsertion = nil
                }

                // If the previous segment is also a remove, overwrite it.
                if isInsertion != .some(false) { i -= 1 }
                endpoints.storage[i] = (x, y)

                isInsertion = false
                k -= 1
            }
        }

        if pathStart != endpoints.storage[i] {
            i -= 1; endpoints.storage[i] = pathStart
        }

        let pathStorage = endpoints.storage
        endpoints.storage = []
        return CollectionChanges(pathStorage: pathStorage, pathStartIndex: i)
    }
}
