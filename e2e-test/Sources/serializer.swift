import Foundation

extension SkirClient {
    // =============================================================================
    // DeserializeError
    // =============================================================================

    enum DeserializeError: Error, CustomStringConvertible {
        case invalidJson(String)
        case schema(String)

        var description: String {
            switch self {
            case let .invalidJson(message):
                return "invalid JSON: \(message)"
            case let .schema(message):
                return message
            }
        }
    }

    // =============================================================================
    // JsonFlavor
    // =============================================================================

    /// When serializing a value to JSON, you can choose one of two flavors.
    public enum JsonFlavor: Equatable {
        /// Structs are serialized as JSON arrays, where the field numbers in the
        /// index definition match the indexes in the array. Enum constants are
        /// serialized as numbers.
        ///
        /// This is the serialization format you should choose in most cases. It is
        /// also the default.
        case dense

        /// Structs are serialized as JSON objects, and enum constants are
        /// serialized as strings.
        ///
        /// This format is more verbose and readable, but it should not be used if
        /// you need persistence, because skir allows fields to be renamed in record
        /// definitions. In other words, never store a readable JSON on disk or in a
        /// database.
        case readable
    }

    // =============================================================================
    // UnrecognizedValues
    // =============================================================================

    /// What to do with unrecognized fields when deserializing a value from dense
    /// JSON or binary data.
    ///
    /// Pick `keep` if the input JSON or binary string comes from a trusted
    /// program which might have been built from more recent source files. Always
    /// pick `drop` if the input JSON or binary string might come from a malicious
    /// user.
    public enum UnrecognizedValues: Equatable {
        /// Unrecognized fields found when deserializing a value are dropped.
        ///
        /// Pick this option if the input JSON or binary string might come from a
        /// malicious user.
        case drop

        /// Unrecognized fields found when deserializing a value from dense JSON or
        /// binary data are saved. If the value is later re-serialized in the same
        /// format (dense JSON or binary), the unrecognized fields will be present
        /// in the serialized form.
        case keep
    }

    // =============================================================================
    // Serializer
    // =============================================================================

    /// Serializes and deserializes values of type `T` in both JSON and binary
    /// formats.
    public final class Serializer<T> {
        private let adapter: any TypeAdapter<T>

        // MARK: - Public API

        /// Serializes `v` to a JSON string.
        public func toJson(_ v: T, flavor: JsonFlavor) -> String {
            var out = ""
            let eolIndent: String?
            switch flavor {
            case .readable:
                eolIndent = "\n"
            case .dense:
                eolIndent = nil
            }
            adapter.toJson(v, eolIndent: eolIndent, out: &out)
            return out
        }

        /// Deserializes a JSON string into a value of type `T`.
        public func fromJson(_ code: String, policy: UnrecognizedValues) throws -> T {
            guard let data = code.data(using: .utf8) else {
                throw DeserializeError.invalidJson("invalid UTF-8 input")
            }
            let jsonValue: Any
            do {
                jsonValue = try JSONSerialization.jsonObject(with: data)
            } catch {
                throw DeserializeError.invalidJson(error.localizedDescription)
            }
            let keepUnrecognized = policy == .keep
            return try adapter.fromJson(jsonValue, keepUnrecognizedValues: keepUnrecognized)
        }

        /// Serializes `v` to the Skir binary wire format.
        ///
        /// The returned bytes are prefixed with the four-byte magic `"skir"`.
        public func toBytes(_ v: T) -> [UInt8] {
            var out: [UInt8] = Array("skir".utf8)
            adapter.encode(v, out: &out)
            return out
        }

        /// Deserializes a value from the Skir binary wire format.
        ///
        /// If `bytes` lacks the `"skir"` prefix the payload is treated as a UTF-8
        /// JSON string and parsed via `fromJson(_:policy:)`.
        public func fromBytes(_ bytes: [UInt8], policy: UnrecognizedValues) throws -> T {
            let keepUnrecognized = policy == .keep
            if bytes.count >= 4 && bytes[0] == 115 && bytes[1] == 107 && bytes[2] == 105 && bytes[3] == 114 {
                // bytes start with "skir"
                var rest = Array(bytes.dropFirst(4))
                return try adapter.decode(&rest, keepUnrecognizedValues: keepUnrecognized)
            } else {
                guard let s = String(bytes: bytes, encoding: .utf8) else {
                    throw DeserializeError.schema("invalid UTF-8 in binary payload")
                }
                return try fromJson(s, policy: policy)
            }
        }

        /// Returns a TypeDescriptor that describes the schema of `T`.
        public func typeDescriptor() -> Reflection.TypeDescriptor {
            return adapter.typeDescriptor()
        }

        func _isDefault(_ value: T) -> Bool {
            adapter.isDefault(value)
        }

        func _toJson(_ value: T, eolIndent: String?, out: inout String) {
            adapter.toJson(value, eolIndent: eolIndent, out: &out)
        }

        func _fromJson(_ json: Any, keepUnrecognizedValues: Bool) throws -> T {
            try adapter.fromJson(json, keepUnrecognizedValues: keepUnrecognizedValues)
        }

        func _encode(_ value: T, out: inout [UInt8]) {
            adapter.encode(value, out: &out)
        }

        func _decode(_ input: inout [UInt8], keepUnrecognizedValues: Bool) throws -> T {
            try adapter.decode(&input, keepUnrecognizedValues: keepUnrecognizedValues)
        }

        // MARK: - Internal Constructors

        /// Constructs a Serializer with a given adapter.
        ///
        /// For use only by code generated by the Skir code generator.
        init(adapter: any TypeAdapter<T>) {
            self.adapter = adapter
        }
    }

    // =============================================================================
    // TypeAdapter Protocol
    // =============================================================================

    /// Internal protocol implemented by every concrete adapter
    /// (primitive, array, optional, struct, enum).
    ///
    /// Only adapters defined in this module can satisfy it.
    /// For use only by code generated by the Skir code generator.
    protocol TypeAdapter<T> {
        associatedtype T

        /// Returns `true` when `input` is the default (zero) value for `T`.
        func isDefault(_ input: T) -> Bool

        /// Writes the JSON representation of `input` to `out`.
        ///
        /// `eolIndent` is `nil` for dense (compact) output. In readable (indented)
        /// mode it is `Some` with a string composed of `"\n"` followed by the
        /// indentation prefix for the current nesting level.
        func toJson(_ input: T, eolIndent: String?, out: inout String)

        /// Deserializes a JSON value into `T`.
        ///
        /// Set `keepUnrecognizedValues` to preserve fields/variants from a newer
        /// schema version that are not recognized by this decoder.
        func fromJson(_ json: Any, keepUnrecognizedValues: Bool) throws -> T

        /// Serializes `input` to the Skir binary wire format, appending bytes to `out`.
        func encode(_ input: T, out: inout [UInt8])

        /// Deserializes a value from the Skir binary wire format, advancing the
        /// slice past the bytes consumed.
        ///
        /// Set `keepUnrecognizedValues` to preserve fields/variants from a newer
        /// schema version.
        func decode(_ input: inout [UInt8], keepUnrecognizedValues: Bool) throws -> T

        /// Returns a TypeDescriptor that describes the schema of `T`.
        func typeDescriptor() -> Reflection.TypeDescriptor
    }
}
