extension OrderedCollection {
    /// Returns a pair of subsequences containing the initial elements that
    /// `self` and `other` have in common.
    public func commonPrefix<Other : OrderedCollection>(
        with other: Other, by areEquivalent: (Element, Other.Element) -> Bool
    ) -> (SubSequence, Other.SubSequence) where Element == Other.Element {
        let (s1, s2) = (startIndex, other.startIndex)
        let (e1, e2) = (endIndex, other.endIndex)
        var (i1, i2) = (s1, s2)
        while i1 != e1 && i2 != e2 {
            if !areEquivalent(self[i1], other[i2]) { break }
            formIndex(after: &i1)
            other.formIndex(after: &i2)
        }
        return (self[s1..<i1], other[s2..<i2])
    }
}
