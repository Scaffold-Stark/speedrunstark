#!/usr/bin/env node
import * as fs from "fs";
import * as toml from "@iarna/toml";

export interface TomlValue {
  [key: string]: any;
}

export function mergeWithOverride(
  target: TomlValue,
  source: TomlValue,
): TomlValue {
  // Git merge: Every key from source (%B) REPLACES matching key in target (%A). Keep unique target keys.
  const result = { ...target };

  for (const [key, value] of Object.entries(source)) {
    if (!(key in result)) {
      // Key doesn't exist in target - add it
      result[key] = value;
    } else if (isTable(result[key]) && isTable(value)) {
      // Both are tables - recursively merge with override
      result[key] = mergeTableWithOverride(result[key], value);
    } else {
      // Key exists - OVERRIDE with source value
      result[key] = value;
    }
  }

  return result;
}

export function mergeTableWithOverride(
  target: TomlValue,
  source: TomlValue,
): TomlValue {
  // Git merge tables: Every key from source table REPLACES matching key in target table.
  const result = { ...target };

  for (const [key, value] of Object.entries(source)) {
    if (!(key in result)) {
      // Key doesn't exist in target table - add it
      result[key] = value;
    } else if (isTable(result[key]) && isTable(value)) {
      // Both are tables - recursively merge with override
      result[key] = mergeTableWithOverride(result[key], value);
    } else {
      // Key exists - OVERRIDE with source value
      result[key] = value;
    }
  }

  return result;
}

export function isTable(value: any): boolean {
  return typeof value === "object" && value !== null && !Array.isArray(value);
}

// New function to preserve formatting and comments
export function mergeTomlPreservingFormat(
  oursContent: string,
  theirsDoc: TomlValue,
): string {
  // Parse ours to get the current structure
  const oursDoc = toml.parse(oursContent) as TomlValue;

  // Perform the merge
  const mergedDoc = mergeWithOverride(oursDoc, theirsDoc);

  // For now, we'll use a simple approach: stringify with minimal formatting
  // In a more advanced version, we could preserve the original formatting
  let mergedContent = toml.stringify(mergedDoc);

  // Clean up the formatting to be more TOML-like
  mergedContent = mergedContent
    .replace(/ = /g, " = ") // Ensure single space around equals
    .replace(/\n\n+/g, "\n\n") // Prevent excessive newlines
    .trim();

  return mergedContent;
}

function main() {
  if (process.argv.length !== 5) {
    console.error("Usage: merge-toml.ts <base> <ours> <theirs>");
    process.exit(1);
  }

  const [, , baseFile, oursFile, theirsFile] = process.argv;

  try {
    // Read TOML files
    const baseContent = fs.readFileSync(baseFile, "utf-8");
    const oursContent = fs.readFileSync(oursFile, "utf-8");
    const theirsContent = fs.readFileSync(theirsFile, "utf-8");

    const baseDoc = toml.parse(baseContent) as TomlValue;
    const theirsDoc = toml.parse(theirsContent) as TomlValue;

    // Git merge driver: %A (current branch) gets modified with %B (other branch) values
    // 1. Start with copy of ours_doc (%A - current branch)
    // 2. Every key from theirs_doc (%B - other branch) REPLACES key in result
    // 3. Keep keys in ours_doc that don't exist in theirs_doc
    // 4. Result written back to %A
    const mergedContent = mergeTomlPreservingFormat(oursContent, theirsDoc);

    // Write merged result back to ours_file
    fs.writeFileSync(oursFile, mergedContent, "utf-8");

    console.log(
      `Git merge: All keys from ${theirsFile} (%B) replaced keys in ${oursFile} (%A), kept unique %A keys`,
    );
    process.exit(0); // Indicate successful merge
  } catch (error) {
    console.error(`Error during TOML merge: ${error}`, error);
    process.exit(1);
  }
}

// Check if this script is being run directly
if (import.meta.url === `file://${process.argv[1]}`) {
  main();
}
