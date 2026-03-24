import { Record, convertCase } from "skir-internal";

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
  return RESERVED_KEYWORDS.has(name) ? name.concat("_") : name;
}

export function toStructFieldName(
  skirName: string,
  fieldRecursivity?: false | "soft" | "via-optional" | "hard",
): string {
  const upperName = convertCase(skirName, "lowerCamel");
  if (fieldRecursivity === "hard") {
    return `_${upperName}_Rec`;
  } else if (RESERVED_KEYWORDS.has(upperName)) {
    return upperName.concat("_");
  } else {
    return upperName;
  }
}

const RESERVED_KEYWORDS = new Set<string>([
  // Keywords used in declarations.
  "associatedtype",
  "class",
  "deinit",
  "enum",
  "extension",
  "fileprivate",
  "func",
  "import",
  "init",
  "inout",
  "internal",
  "let",
  "open",
  "operator",
  "private",
  "protocol",
  "public",
  "rethrows",
  "static",
  "struct",
  "subscript",
  "typealias",
  "var",

  // Keywords used in statements.
  "break",
  "case",
  "continue",
  "default",
  "defer",
  "do",
  "else",
  "fallthrough",
  "for",
  "guard",
  "if",
  "in",
  "repeat",
  "return",
  "switch",
  "where",
  "while",

  // Keywords used in expressions and types.
  "Any",
  "as",
  "catch",
  "false",
  "is",
  "nil",
  "Self",
  "self",
  "super",
  "throw",
  "throws",
  "true",
  "try",

  // Contextual / special-purpose keywords that commonly conflict with identifiers.
  "actor",
  "any",
  "associativity",
  "async",
  "await",
  "borrowing",
  "convenience",
  "consuming",
  "didSet",
  "distributed",
  "dynamic",
  "final",
  "get",
  "indirect",
  "infix",
  "isolated",
  "lazy",
  "left",
  "mutating",
  "none",
  "nonmutating",
  "optional",
  "override",
  "package",
  "postfix",
  "precedence",
  "prefix",
  "Protocol",
  "required",
  "right",
  "set",
  "some",
  "Type",
  "unowned",
  "weak",
  "willSet",
]);
