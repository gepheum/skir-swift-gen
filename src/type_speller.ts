import type { RecordKey, RecordLocation, ResolvedType } from "skir-internal";
import { getSpecName, keyTypeIsSupported } from "./keyed_array_context.js";
import { getTypeRef, ModuleContext } from "./naming.js";

/**
 * Transforms a type found in a `.skir` file into a Swift type.
 */
export class TypeSpeller {
  constructor(readonly recordMap: ReadonlyMap<RecordKey, RecordLocation>) {}

  getSwiftType(
    type: ResolvedType,
    context: RecordLocation | ModuleContext | null,
    fieldRecursivity?: false | "soft" | "via-optional" | "hard",
  ): string {
    switch (type.kind) {
      case "record": {
        const recordLocation = this.recordMap.get(type.key)!;
        const typeRef = getTypeRef(recordLocation, context);
        return fieldRecursivity === "hard"
          ? `SkirClient.Box<${typeRef}>?`
          : typeRef;
      }
      case "array": {
        const itemType = this.getSwiftType(type.item, context);
        if (type.key && keyTypeIsSupported(type.key.keyType)) {
          const specName = getSpecName(type.key);
          return `SkirClient.KeyedArray<${itemType}.${specName}>`;
        } else {
          return `[${itemType}]`;
        }
      }
      case "optional": {
        const otherType = this.getSwiftType(type.other, context);
        return fieldRecursivity === "via-optional"
          ? `SkirClient.Box<${otherType}>?`
          : `${otherType}?`;
      }
      case "primitive": {
        const { primitive } = type;
        switch (primitive) {
          case "bool":
            return "Bool";
          case "int32":
            return "Int32";
          case "int64":
            return "Int64";
          case "float32":
            return "Float";
          case "float64":
            return "Double";
          case "string":
            return "String";
          case "hash64":
            return "UInt64";
          case "timestamp":
            return "Foundation.Date";
          case "bytes":
            return "Foundation.Data";
        }
      }
    }
  }

  getSerializerExpression(type: ResolvedType): string {
    switch (type.kind) {
      case "primitive": {
        switch (type.primitive) {
          case "bool":
            return "SkirClient.Serializer.bool()";
          case "int32":
            return "SkirClient.Serializer.int32()";
          case "int64":
            return "SkirClient.Serializer.int64()";
          case "hash64":
            return "SkirClient.Serializer.hash64()";
          case "float32":
            return "SkirClient.Serializer.float32()";
          case "float64":
            return "SkirClient.Serializer.float64()";
          case "timestamp":
            return "SkirClient.Serializer.timestamp()";
          case "string":
            return "SkirClient.Serializer.string()";
          case "bytes":
            return "SkirClient.Serializer.bytes()";
        }
        const _: never = type.primitive;
        throw TypeError();
      }
      case "array": {
        if (type.key) {
          const keyExtractor = type.key.path
            .map((part) => part.name.text)
            .join(".");
          return (
            "SkirClient.Serializer.array(\n" +
            this.getSerializerExpression(type.item) +
            ", keyExtractor: " +
            JSON.stringify(keyExtractor) +
            "\n)"
          );
        } else {
          return (
            "SkirClient.Serializer.array(\n" +
            this.getSerializerExpression(type.item) +
            ', keyExtractor: ""\n)'
          );
        }
      }
      case "optional": {
        return (
          "SkirClient.Serializer.optional(\n" +
          this.getSerializerExpression(type.other) +
          "\n)"
        );
      }
      case "record": {
        return "foo";
      }
    }
  }

  getDefaultExpression(
    type: ResolvedType,
    context: RecordLocation | ModuleContext,
    fieldRecursivity?: false | "soft" | "via-optional" | "hard",
  ): string {
    switch (type.kind) {
      case "primitive": {
        switch (type.primitive) {
          case "bool":
            return "false";
          case "int32":
          case "int64":
          case "hash64":
          case "float32":
          case "float64":
            return "0";
          case "string":
            return '""';
          case "timestamp":
            return "Foundation.Date(timeIntervalSince1970: 0)";
          case "bytes":
            return "Foundation.Data()";
        }
        const _: never = type.primitive;
        throw TypeError();
      }
      case "array": {
        return "[]";
      }
      case "optional": {
        return "nil";
      }
      case "record": {
        if (fieldRecursivity === "hard") {
          return "nil";
        } else {
          const typeName = this.getSwiftType(type, context, fieldRecursivity);
          const { recordType } = this.recordMap.get(type.key)!.record;
          return recordType === "struct"
            ? `${typeName}.defaultValue`
            : `${typeName}.unknownValue`;
        }
      }
    }
  }
}
