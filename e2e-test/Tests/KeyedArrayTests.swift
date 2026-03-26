import XCTest
@testable import e2e_test

final class KeyedArrayTests: XCTestCase {
    // Convenience alias: array of Item keyed by the `string` field.
    typealias StringKeyedItems = SkirClient.KeyedArray<Structs_skir.Item.By_String>

    private func makeItem(string: String, int32: Int32 = 0) -> Structs_skir.Item {
        Structs_skir.Item.partial(string: string, int32: int32)
    }

    // MARK: - Basic collection behaviour

    func testEmptyArrayHasZeroCount() {
        let ka = StringKeyedItems()
        XCTAssertEqual(ka.count, 0)
        XCTAssertTrue(ka.isEmpty)
    }

    func testCountMatchesInitialItems() {
        let ka = StringKeyedItems([makeItem(string: "a"), makeItem(string: "b")])
        XCTAssertEqual(ka.count, 2)
    }

    func testSubscriptReturnsItemAtIndex() {
        let item = makeItem(string: "hello")
        let ka = StringKeyedItems([item])
        XCTAssertEqual(ka[0].string, "hello")
    }

    func testIterationYieldsAllItemsInOrder() {
        let items = ["x", "y", "z"].map { makeItem(string: $0) }
        let ka = StringKeyedItems(items)
        XCTAssertEqual(ka.map(\.string), ["x", "y", "z"])
    }

    // MARK: - Key-based lookup

    func testFindByKeyReturnsMatchingItem() {
        let ka = StringKeyedItems([makeItem(string: "foo"), makeItem(string: "bar")])
        XCTAssertEqual(ka.findByKey("foo")?.string, "foo")
        XCTAssertEqual(ka.findByKey("bar")?.string, "bar")
    }

    func testFindByKeyReturnsNilForMissingKey() {
        let ka = StringKeyedItems([makeItem(string: "foo")])
        XCTAssertNil(ka.findByKey("missing"))
    }

    func testFindByKeyOrDefaultReturnsItemWhenFound() {
        let ka = StringKeyedItems([makeItem(string: "foo", int32: 42)])
        XCTAssertEqual(ka.findByKeyOrDefault("foo").int32, 42)
    }

    func testFindByKeyOrDefaultReturnsDefaultItemWhenMissing() {
        let ka = StringKeyedItems()
        let result = ka.findByKeyOrDefault("nope")
        XCTAssertEqual(result, Structs_skir.Item.defaultValue)
    }

    func testDuplicateKeyReturnsFirstOccurrence() {
        let first = makeItem(string: "dup", int32: 1)
        let second = makeItem(string: "dup", int32: 2)
        let ka = StringKeyedItems([first, second])
        XCTAssertEqual(ka.findByKey("dup")?.int32, 1)
    }

    // MARK: - Equatable

    func testEqualArraysAreEqual() {
        let items = [makeItem(string: "a"), makeItem(string: "b")]
        XCTAssertEqual(StringKeyedItems(items), StringKeyedItems(items))
    }

    func testDifferentOrderIsNotEqual() {
        let ka1 = StringKeyedItems([makeItem(string: "a"), makeItem(string: "b")])
        let ka2 = StringKeyedItems([makeItem(string: "b"), makeItem(string: "a")])
        XCTAssertNotEqual(ka1, ka2)
    }

    func testEmptyArraysAreEqual() {
        XCTAssertEqual(StringKeyedItems(), StringKeyedItems())
    }

    // MARK: - ExpressibleByArrayLiteral

    func testArrayLiteralInit() {
        let ka: StringKeyedItems = [makeItem(string: "lit")]
        XCTAssertEqual(ka.count, 1)
        XCTAssertEqual(ka[0].string, "lit")
    }

    // MARK: - CustomStringConvertible

    func testEmptyDescriptionMatchesEmptyArray() {
        let ka = StringKeyedItems()
        XCTAssertEqual(ka.description, "[]")
    }

    func testDescriptionMatchesArrayWithSameItems() {
        let items = [makeItem(string: "p"), makeItem(string: "q")]
        let ka = StringKeyedItems(items)
        XCTAssertEqual(ka.description, items.description)
    }
}
