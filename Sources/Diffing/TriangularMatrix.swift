/// Returns the nth [triangular number].
///
/// [triangular number]: https://en.wikipedia.org/wiki/Triangular_number
fileprivate func triangularNumber(_ n: Int) -> Int {
    return n * (n + 1) / 2
}

/// A square matrix that only provides subscript access to elements on, or
/// below, the main diagonal.
///
/// A [lower triangular matrix] can be dynamically grown:
///
///     var m = LowerTriangularMatrix<Int>()
///     m.appendRow(repeating: 1)
///     m.appendRow(repeating: 2)
///     m.appendRow(repeating: 3)
///
///     assert(Array(m.rowMajorOrder) == [
///         1,
///         2, 2,
///         3, 3, 3,
///     ])
///
/// [lower triangular matrix]: http://en.wikipedia.org/wiki/Triangular_matrix
struct LowerTriangularMatrix<Element> {
    /// The matrix elements stored in [row major order][rmo].
    ///
    /// [rmo]: http://en.wikipedia.org/wiki/Row-_and_column-major_order
    var storage: [Element] = []

    /// The dimension of the matrix.
    ///
    /// Being a square matrix, the number of rows and columns are equal.
    var dimension: Int = 0

    subscript(row: Int, column: Int) -> Element {
        get {
            assert((0...row).contains(column))
            return storage[triangularNumber(row) + column]
        }
        set {
            assert((0...row).contains(column))
            storage[triangularNumber(row) + column] = newValue
        }
    }

    mutating func appendRow(repeating repeatedValue: Element) {
        dimension += 1
        storage.append(contentsOf: repeatElement(repeatedValue, count: dimension))
    }
}

extension LowerTriangularMatrix {
    /// A collection that visits the elements in the matrix in [row major
    /// order][rmo].
    ///
    /// [rmo]: http://en.wikipedia.org/wiki/Row-_and_column-major_order
    struct RowMajorOrder : RandomAccessCollection {
        var base: LowerTriangularMatrix

        var startIndex: Int {
            return base.storage.startIndex
        }

        var endIndex: Int {
            return base.storage.endIndex
        }

        func index(after i: Int) -> Int {
            return i + 1
        }

        func index(before i: Int) -> Int {
            return i - 1
        }

        subscript(position: Int) -> Element {
            return base.storage[position]
        }
    }

    var rowMajorOrder: RowMajorOrder {
        return RowMajorOrder(base: self)
    }

    subscript(row r: Int) -> Slice<RowMajorOrder> {
        return rowMajorOrder[triangularNumber(r)..<triangularNumber(r + 1)]
    }
}

extension LowerTriangularMatrix : CustomStringConvertible {
    var description: String {
        var rows: [[Element]] = []
        for row in 0..<dimension {
            rows.append(Array(self[row: row]))
        }
        return String(describing: rows)
    }
}
