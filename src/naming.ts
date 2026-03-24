import {
  type Field,
  Record,
  type RecordLocation,
  convertCase,
} from "skir-internal";

export function modulePathToCaselessEnumName(modulePath: string): string {
  return modulePath
    .replace(/^@/, "external/")
    .replace(/\.skir$/, "")
    .split("/")
    .map((part) => convertCase(part.replace(/-/g, "_"), "UpperCamel"))
    .join("_")
    .concat("_skir");
}

/** Returns the name of the Swift type for the given Skir record. */
export function getTypeName(record: Record): string {
  const name = record.name.text;
  return name === "Self" ? name.concat("_") : name;
}

// TODO: change
export function structFieldToGetterName(field: Field | string): string {
  const skirName = typeof field === "string" ? field : field.name.text;
  const upperCamel = convertCase(skirName, "UpperCamel");
  return skirName.startsWith("search_") ||
    skirName === "string" ||
    skirName === "to_builder"
    ? upperCamel.concat("_")
    : upperCamel;
}

// TODO: change
/** Returns the name of the frozen Go struct for the given record. */
export function getClassName(record: RecordLocation): string {
  return record.recordAncestors.map((r) => r.name.text).join("_");
}
