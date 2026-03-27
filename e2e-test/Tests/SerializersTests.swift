import Foundation
import SkirClient
import XCTest

final class SerializersTests: XCTestCase {

  // MARK: - Bool

  func testBoolJsonRoundTrip() throws {
    let s = Serializer<Bool>.bool()
    XCTAssertEqual(try s.fromJson(s.toJson(true)), true)
    XCTAssertEqual(try s.fromJson(s.toJson(false)), false)
  }

  func testBoolBinaryRoundTrip() throws {
    let s = Serializer<Bool>.bool()
    XCTAssertEqual(try s.fromBytes(s.toBytes(true)), true)
    XCTAssertEqual(try s.fromBytes(s.toBytes(false)), false)
  }

  // MARK: - Int32

  func testInt32JsonRoundTrip() throws {
    let s = Serializer<Int32>.int32()
    XCTAssertEqual(try s.fromJson(s.toJson(42)), 42)
    XCTAssertEqual(try s.fromJson(s.toJson(-1)), -1)
  }

  func testInt32BinaryRoundTrip() throws {
    let s = Serializer<Int32>.int32()
    XCTAssertEqual(try s.fromBytes(s.toBytes(42)), 42)
    XCTAssertEqual(try s.fromBytes(s.toBytes(-1)), -1)
  }

  // MARK: - Int64

  func testInt64JsonRoundTrip() throws {
    let s = Serializer<Int64>.int64()
    XCTAssertEqual(try s.fromJson(s.toJson(123)), 123)
    // Values within the JS safe integer range are serialized as numbers.
    XCTAssertEqual(try s.fromJson(s.toJson(9_007_199_254_740_991)), 9_007_199_254_740_991)
  }

  func testInt64BinaryRoundTrip() throws {
    let s = Serializer<Int64>.int64()
    XCTAssertEqual(try s.fromBytes(s.toBytes(Int64.max)), Int64.max)
    XCTAssertEqual(try s.fromBytes(s.toBytes(Int64.min)), Int64.min)
  }

  // MARK: - Hash64 (UInt64)

  func testHash64JsonRoundTrip() throws {
    let s = Serializer<UInt64>.hash64()
    XCTAssertEqual(try s.fromJson(s.toJson(42)), 42)
  }

  func testHash64BinaryRoundTrip() throws {
    let s = Serializer<UInt64>.hash64()
    XCTAssertEqual(try s.fromBytes(s.toBytes(UInt64.max)), UInt64.max)
  }

  // MARK: - Float32

  func testFloat32JsonRoundTrip() throws {
    let s = Serializer<Float>.float32()
    XCTAssertEqual(try s.fromJson(s.toJson(1.5)), 1.5, accuracy: 1e-6)
  }

  func testFloat32BinaryRoundTrip() throws {
    let s = Serializer<Float>.float32()
    XCTAssertEqual(try s.fromBytes(s.toBytes(3.14)), 3.14, accuracy: 1e-5)
  }

  // MARK: - Float64

  func testFloat64JsonRoundTrip() throws {
    let s = Serializer<Double>.float64()
    XCTAssertEqual(try s.fromJson(s.toJson(1.5)), 1.5, accuracy: 1e-15)
  }

  func testFloat64BinaryRoundTrip() throws {
    let s = Serializer<Double>.float64()
    XCTAssertEqual(try s.fromBytes(s.toBytes(Double.pi)), Double.pi, accuracy: 1e-15)
  }

  // MARK: - Timestamp

  func testTimestampJsonRoundTrip() throws {
    let s = Serializer<Date>.timestamp()
    let date = Date(timeIntervalSince1970: 1_000_000)
    let result = try s.fromJson(s.toJson(date))
    XCTAssertEqual(result.timeIntervalSince1970, date.timeIntervalSince1970, accuracy: 0.001)
  }

  func testTimestampBinaryRoundTrip() throws {
    let s = Serializer<Date>.timestamp()
    let date = Date(timeIntervalSince1970: 1_703_984_028)
    let result = try s.fromBytes(s.toBytes(date))
    XCTAssertEqual(result.timeIntervalSince1970, date.timeIntervalSince1970, accuracy: 0.001)
  }

  // MARK: - String

  func testStringJsonRoundTrip() throws {
    let s = Serializer<String>.string()
    XCTAssertEqual(try s.fromJson(s.toJson("hello")), "hello")
    XCTAssertEqual(try s.fromJson(s.toJson("")), "")
  }

  func testStringBinaryRoundTrip() throws {
    let s = Serializer<String>.string()
    XCTAssertEqual(try s.fromBytes(s.toBytes("hello")), "hello")
  }

  // MARK: - Bytes (Data)

  func testBytesJsonRoundTrip() throws {
    let s = Serializer<Data>.bytes()
    let data = Data([0x01, 0x02, 0x03])
    XCTAssertEqual(try s.fromJson(s.toJson(data)), data)
  }

  func testBytesBinaryRoundTrip() throws {
    let s = Serializer<Data>.bytes()
    let data = Data([0xDE, 0xAD, 0xBE, 0xEF])
    XCTAssertEqual(try s.fromBytes(s.toBytes(data)), data)
  }

  // MARK: - Array

  func testArrayJsonRoundTrip() throws {
    let s: Serializer<[Int32]> = .array(.int32())
    let value: [Int32] = [1, 2, 3]
    XCTAssertEqual(try s.fromJson(s.toJson(value)), value)
  }

  func testArrayBinaryRoundTrip() throws {
    let s: Serializer<[Int32]> = .array(.int32())
    let value: [Int32] = [10, 20, 30]
    XCTAssertEqual(try s.fromBytes(s.toBytes(value)), value)
  }

  func testEmptyArrayRoundTrip() throws {
    let s: Serializer<[String]> = .array(.string())
    XCTAssertEqual(try s.fromJson(s.toJson([])), [])
  }

  // MARK: - Optional

  func testOptionalSomeJsonRoundTrip() throws {
    let s: Serializer<Int32?> = .optional(.int32())
    XCTAssertEqual(try s.fromJson(s.toJson(99)), 99)
  }

  func testOptionalNoneJsonRoundTrip() throws {
    let s: Serializer<Int32?> = .optional(.int32())
    XCTAssertNil(try s.fromJson(s.toJson(nil)))
  }

  func testOptionalBinaryRoundTrip() throws {
    let s: Serializer<String?> = .optional(.string())
    XCTAssertEqual(try s.fromBytes(s.toBytes("test")), "test")
    XCTAssertNil(try s.fromBytes(s.toBytes(nil)))
  }
}
