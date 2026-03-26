import XCTest
@testable import e2e_test

final class GeneratedStructsTests: XCTestCase {
    func testDefaultValueHasExpectedZeros() {
        let point = Structs_skir.Point.defaultValue
        XCTAssertEqual(point.x, 0)
        XCTAssertEqual(point.y, 0)
    }

    func testPartialFactorySetsProvidedFieldsOnly() {
        let point = Structs_skir.Point.partial(x: 12)
        XCTAssertEqual(point.x, 12)
        XCTAssertEqual(point.y, 0)
    }

    func testCopyKeepsAndSetsFields() {
        let original = FullName_skir.FullName.partial(firstName: "Ada", lastName: "Lovelace")
        let updated = original.copy(lastName: .set("Byron"))

        XCTAssertEqual(updated.firstName, "Ada")
        XCTAssertEqual(updated.lastName, "Byron")
    }

    func testDescriptionUsesReadableJson() {
        let point = Structs_skir.Point.partial(x: 1, y: 2)
        let description = point.description

        XCTAssertTrue(description.contains("\n"))
        XCTAssertTrue(description.contains("\"x\""))
        XCTAssertTrue(description.contains("\"y\""))
    }

    // MARK: - Serialization

    func testJsonRoundTrip() {
        let point = Structs_skir.Point.partial(x: 42, y: -7)
        let serializer = Structs_skir.Point.serializer
        let json = serializer.toJson(point)
        let decoded = try! serializer.fromJson(json)
        XCTAssertEqual(decoded.x, 42)
        XCTAssertEqual(decoded.y, -7)
    }

    func testBinaryRoundTrip() {
        let point = Structs_skir.Point.partial(x: 100, y: 200)
        let serializer = Structs_skir.Point.serializer
        let bytes = serializer.toBytes(point)
        XCTAssertEqual(bytes[0..<4], [115, 107, 105, 114])  // "skir" magic prefix
        let decoded = try! serializer.fromBytes(bytes)
        XCTAssertEqual(decoded.x, 100)
        XCTAssertEqual(decoded.y, 200)
    }

    func testCompactJsonOmitsFieldNames() {
        let point = Structs_skir.Point.partial(x: 1, y: 2)
        let json = Structs_skir.Point.serializer.toJson(point)
        XCTAssertFalse(json.contains("\"x\""))
        XCTAssertFalse(json.contains("\"y\""))
        XCTAssertFalse(json.contains("\n"))
    }

    func testDefaultValueRoundTrip() {
        let serializer = Structs_skir.Point.serializer
        let bytes = serializer.toBytes(Structs_skir.Point.defaultValue)
        let decoded = try! serializer.fromBytes(bytes)
        XCTAssertEqual(decoded.x, 0)
        XCTAssertEqual(decoded.y, 0)
    }
}
