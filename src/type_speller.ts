import type { RecordKey, RecordLocation, ResolvedType } from "skir-internal";
import { ModuleContext, modulePathToCaselessEnumName } from "./naming.js";

/**
 * Transforms a type found in a `.skir` file into a Swift type.
 */
export class TypeSpeller {
  constructor(readonly recordMap: ReadonlyMap<RecordKey, RecordLocation>) {}

  getSwiftType(
    type: ResolvedType,
    context: RecordLocation | ModuleContext,
    fieldRecursivity?: false | "soft" | "via-optional" | "hard",
  ): string {
    switch (type.kind) {
      case "record": {
        const recordLocation = this.recordMap.get(type.key)!;
        const caselessEnumName = modulePathToCaselessEnumName(
          recordLocation.modulePath,
        );
        const qualifiedName = [
          caselessEnumName,
          ...recordLocation.recordAncestors.map((r) => r.name.text),
        ].join(".");
        return fieldRecursivity === "hard"
          ? `SkirClient.Box<${qualifiedName}>?`
          : qualifiedName;
      }
      case "array": {
        const itemType = this.getSwiftType(type.item, context);
        return `[${itemType}]`;
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
            return "skir_client.BoolSerializer()";
          case "int32":
            return "skir_client.Int32Serializer()";
          case "int64":
            return "skir_client.Int64Serializer()";
          case "hash64":
            return "skir_client.Hash64Serializer()";
          case "float32":
            return "skir_client.Float32Serializer()";
          case "float64":
            return "skir_client.Float64Serializer()";
          case "timestamp":
            return "skir_client.TimestampSerializer()";
          case "string":
            return "skir_client.StringSerializer()";
          case "bytes":
            return "skir_client.BytesSerializer()";
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
            "skir_client.Internal__ArraySerializer(\n" +
            this.getSerializerExpression(type.item) +
            ",\n" +
            JSON.stringify(keyExtractor) +
            ",\n)"
          );
        } else {
          return (
            "skir_client.ArraySerializer(\n" +
            this.getSerializerExpression(type.item) +
            ",\n)"
          );
        }
      }
      case "optional": {
        return (
          "skir_client.OptionalSerializer(\n" +
          this.getSerializerExpression(type.other) +
          ",\n)"
        );
      }
      case "record": {
        const recordLocation = this.recordMap.get(type.key)!;
        // const className = getClassName(recordLocation);
        // const packageAlias = modulePathToAlias(recordLocation.modulePath);
        // return `${packageAlias}.${className}_serializer()`;
        return "FOO";
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
          return `${typeName}.defaultValue`;
        }
      }
    }
  }
}
