/// An ordered collection treats the structural positions of its elements as
/// part of its interface. Differences in order always affect whether two
/// instances are equal.
///
/// For example, a tree is an ordered collection; a dictionary is not.
//@available(swift, introduced: 5.1)
public protocol OrderedCollection : Collection
    where SubSequence : OrderedCollection
{
    /// Returns a Boolean value indicating whether this ordered collection and
    /// another ordered collection contain equivalent elements in the same
    /// order, using the given predicate as the equivalence test.
    ///
    /// The predicate must be a *equivalence relation* over the elements. That
    /// is, for any elements `a`, `b`, and `c`, the following conditions must
    /// hold:
    ///
    /// - `areEquivalent(a, a)` is always `true`. (Reflexivity)
    /// - `areEquivalent(a, b)` implies `areEquivalent(b, a)`. (Symmetry)
    /// - If `areEquivalent(a, b)` and `areEquivalent(b, c)` are both `true`,
    ///   then `areEquivalent(a, c)` is also `true`. (Transitivity)
    ///
    /// - Parameters:
    ///   - other: An ordered collection to compare to this ordered collection.
    ///   - areEquivalent: A predicate that returns `true` if its two arguments
    ///     are equivalent; otherwise, `false`.
    /// - Returns: `true` if this ordered collection and `other` contain
    ///   equivalent items, using `areEquivalent` as the equivalence test;
    ///   otherwise, `false.`
    ///
    /// - Complexity: O(*m*), where *m* is the lesser of the length of the
    ///   ordered collection and the length of `other`.
    func elementsEqual<C>(
        _ other: C, by areEquivalent: (Element, C.Element) throws -> Bool
    ) rethrows -> Bool where C : OrderedCollection
}

extension OrderedCollection {
    /// Returns the difference needed to produce the receiver's state from the
    /// parameter's state, using the provided closure to establish equivalence
    /// between elements.
    ///
    /// This function does not infer element moves, but they can be computed
    /// using `OrderedCollectionDifference.inferringMoves()` if
    /// desired.
    ///
    /// Implementation is an optimized variation of the algorithm described by
    /// E. Myers (1986).
    ///
    /// - Parameters:
    ///   - other: The base state.
    ///   - areEquivalent: A closure that returns whether the two
    ///     parameters are equivalent.
    ///
    /// - Returns: The difference needed to produce the reciever's state from
    ///   the parameter's state.
    ///
    /// - Complexity: O(*n* * *d*), where *n* is `other.count + self.count` and
    ///   *d* is the number of differences between the two ordered collections.
    public func difference<C>(
        from other: C, by areEquivalent: (Element, C.Element) -> Bool
    ) -> OrderedCollectionDifference<Element>
        where C : OrderedCollection, C.Element == Self.Element
    {
        var rawChanges: [OrderedCollectionDifference<Element>.Change] = []
        
        let source = CountingIndexCollection(other)
        let target = CountingIndexCollection(self)
        for c in CollectionChanges(from: source, to: target, by: areEquivalent) {
            switch c {
            case let .removed(r):
                for i in source.indices[r] {
                    rawChanges.append(
                        .remove(
                            offset: i.offset!,
                            element: source[i],
                            associatedWith: nil))
                }
            case let .inserted(r):
                for i in target.indices[r] {
                    rawChanges.append(
                        .insert(
                            offset: i.offset!,
                            element: target[i],
                            associatedWith: nil))
                }
            case .matched: break
            }
        }
        
        return OrderedCollectionDifference<Element>(validatedChanges: rawChanges)
    }
}

extension OrderedCollection where Element : Equatable {
    /// Returns a Boolean value indicating whether this ordered collection and
    /// another ordered collection contain the same elements in the same order.
    ///
    /// This example tests whether one countable range shares the same elements
    /// as another countable range and an array.
    ///
    ///     let a = 1...3
    ///     let b = 1...10
    ///
    ///     print(a.elementsEqual(b))
    ///     // Prints "false"
    ///     print(a.elementsEqual([1, 2, 3]))
    ///     // Prints "true"
    ///
    /// - Parameter other: An ordered collection to compare to this ordered
    ///   collection.
    /// - Returns: `true` if this ordered collection and `other` contain the
    ///   same elements in the same order.
    ///
    /// - Complexity: O(*m*), where *m* is the lesser of the `count` of the
    ///   ordered collection and the `count` of `other`.
    public func elementsEqual<C>(_ other: C) -> Bool
        where C : OrderedCollection, C.Element == Element
    {
        return self.elementsEqual(other, by: ==)
    }
    
    /// Returns the difference needed to produce the receiver's state from the
    /// parameter's state, using equality to establish equivalence between
    /// elements.
    ///
    /// This function does not infer element moves, but they can be computed
    /// using `OrderedCollectionDifference.inferringMoves()` if
    /// desired.
    ///
    /// Implementation is an optimized variation of the algorithm described by
    /// E. Myers (1986).
    ///
    /// - Parameters:
    ///   - other: The base state.
    ///
    /// - Returns: The difference needed to produce the reciever's state from
    ///   the parameter's state.
    ///
    /// - Complexity: O(*n* * *d*), where *n* is `other.count + self.count` and
    ///   *d* is the number of differences between the two ordered collections.
    public func difference<C>(from other: C) -> OrderedCollectionDifference<Element>
        where C: OrderedCollection, C.Element == Self.Element
    {
        return difference(from: other, by: ==)
    }
}

// extension BidirectionalCollection : OrderedCollection {}
// Implies the following:
extension Array : OrderedCollection {}
extension ArraySlice : OrderedCollection {}
extension ClosedRange : OrderedCollection where Bound : Strideable, Bound.Stride : SignedInteger {}
extension CollectionOfOne : OrderedCollection {}
extension ContiguousArray : OrderedCollection {}
extension EmptyCollection : OrderedCollection {}
extension Range : OrderedCollection where Bound : Strideable, Bound.Stride : SignedInteger {}
extension UnsafeBufferPointer : OrderedCollection {}
extension UnsafeMutableBufferPointer : OrderedCollection {}
import Foundation
#if swift(>=5.0)
extension DataProtocol : OrderedCollection {}
#else
extension Data : OrderedCollection {}
#endif
extension IndexPath : OrderedCollection {}

// Unidirectional collection adoption of OrderedCollection:
extension CountingIndexCollection : OrderedCollection where Base : OrderedCollection {}
extension Slice : OrderedCollection where Base : OrderedCollection {}
extension String : OrderedCollection {}
extension Substring : OrderedCollection {}
extension UnsafeMutableRawBufferPointer : OrderedCollection {}
extension UnsafeRawBufferPointer : OrderedCollection {}
