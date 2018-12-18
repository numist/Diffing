extension RangeReplaceableCollection {
    @inline(__always) private static func fastApplicationEnumeration(
        of diff: OrderedCollectionDifference<Element>,
        _ f: (OrderedCollectionDifference<Element>.Change) -> Void
    ) {
        let totalRemoves = diff.removals.count
        let totalInserts = diff.insertions.count
        var enumeratedRemoves = 0
        var enumeratedInserts = 0
        
        while enumeratedRemoves < totalRemoves || enumeratedInserts < totalInserts {
            let consume: OrderedCollectionDifference<Element>.Change
            if enumeratedRemoves < diff.removals.count && enumeratedInserts < diff.insertions.count {
                let removeOffset = diff.removals[enumeratedRemoves].offset
                let insertOffset = diff.insertions[enumeratedInserts].offset
                if removeOffset - enumeratedRemoves <= insertOffset - enumeratedInserts {
                    consume = diff.removals[enumeratedRemoves]
                } else {
                    consume = diff.insertions[enumeratedInserts]
                }
            } else if enumeratedRemoves < totalRemoves {
                consume = diff.removals[enumeratedRemoves]
            } else if enumeratedInserts < totalInserts {
                consume = diff.insertions[enumeratedInserts]
            } else {
                // Not reached, loop should have exited.
                preconditionFailure()
            }
            
            f(consume)
            
            switch consume {
            case .remove(_, _, _):
                enumeratedRemoves += 1
            case .insert(_, _, _):
                enumeratedInserts += 1
            }
        }
    }
    
    /// Applies a difference to a collection.
    ///
    /// - Parameter difference: The difference to be applied.
    ///
    /// - Returns: An instance representing the state of the receiver with the
    ///   difference applied, or `nil` if the difference is incompatible with
    ///   the receiver's state.
    ///
    /// - Complexity: O(*n* + *c*), where *n* is `self.count` and *c* is the
    ///   number of changes contained by the parameter.
//    @available(swift, introduced: 5.1)
    public func applying(_ difference: OrderedCollectionDifference<Element>) -> Self? {
        var result = Self()
        var enumeratedRemoves = 0
        var enumeratedInserts = 0
        var enumeratedOriginals = 0
        var currentIndex = self.startIndex

        func append(into target: inout Self, contentsOf source: Self, from index: inout Self.Index, count: Int) {
            let start = index
            source.formIndex(&index, offsetBy: count)
            target.append(contentsOf: source[start..<index])
        }
        
        Self.fastApplicationEnumeration(of: difference) { change in
            switch change {
            case .remove(offset: let offset, element: _, associatedWith: _):
                let origCount = offset - enumeratedOriginals
                append(into: &result, contentsOf: self, from: &currentIndex, count: origCount)
                enumeratedOriginals += origCount + 1 // Removal consumes an original element
                currentIndex = self.index(after: currentIndex)
                enumeratedRemoves += 1
            case .insert(offset: let offset, element: let element, associatedWith: _):
                let origCount = (offset + enumeratedRemoves - enumeratedInserts) - enumeratedOriginals
                append(into: &result, contentsOf: self, from: &currentIndex, count: origCount)
                result.append(element)
                enumeratedOriginals += origCount
                enumeratedInserts += 1
            }
            assert(enumeratedOriginals <= self.count)
        }
        let origCount = self.count - enumeratedOriginals
        append(into: &result, contentsOf: self, from: &currentIndex, count: origCount)

        assert(currentIndex == self.endIndex)
        assert(enumeratedOriginals + origCount == self.count)
        assert(result.count == self.count + enumeratedInserts - enumeratedRemoves)
        return result
    }
}
