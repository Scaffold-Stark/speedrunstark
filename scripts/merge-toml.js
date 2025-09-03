#!/usr/bin/env node
"use strict";
var __assign = (this && this.__assign) || function () {
    __assign = Object.assign || function(t) {
        for (var s, i = 1, n = arguments.length; i < n; i++) {
            s = arguments[i];
            for (var p in s) if (Object.prototype.hasOwnProperty.call(s, p))
                t[p] = s[p];
        }
        return t;
    };
    return __assign.apply(this, arguments);
};
Object.defineProperty(exports, "__esModule", { value: true });
var fs = require("fs");
var toml = require("@iarna/toml");
function mergeWithOverride(target, source) {
    // Git merge: Every key from source (%B) REPLACES matching key in target (%A). Keep unique target keys.
    var result = __assign({}, target);
    for (var _i = 0, _a = Object.entries(source); _i < _a.length; _i++) {
        var _b = _a[_i], key = _b[0], value = _b[1];
        if (!(key in result)) {
            // Key doesn't exist in target - add it
            result[key] = value;
        }
        else if (isTable(result[key]) && isTable(value)) {
            // Both are tables - recursively merge with override
            result[key] = mergeTableWithOverride(result[key], value);
        }
        else {
            // Key exists - OVERRIDE with source value
            result[key] = value;
        }
    }
    return result;
}
function mergeTableWithOverride(target, source) {
    // Git merge tables: Every key from source table REPLACES matching key in target table.
    var result = __assign({}, target);
    for (var _i = 0, _a = Object.entries(source); _i < _a.length; _i++) {
        var _b = _a[_i], key = _b[0], value = _b[1];
        if (!(key in result)) {
            // Key doesn't exist in target table - add it
            result[key] = value;
        }
        else if (isTable(result[key]) && isTable(value)) {
            // Both are tables - recursively merge with override
            result[key] = mergeTableWithOverride(result[key], value);
        }
        else {
            // Key exists - OVERRIDE with source value
            result[key] = value;
        }
    }
    return result;
}
function isTable(value) {
    return typeof value === "object" && value !== null && !Array.isArray(value);
}
// New function to preserve formatting and comments
function mergeTomlPreservingFormat(oursContent, theirsDoc) {
    // Parse ours to get the current structure
    var oursDoc = toml.parse(oursContent);
    // Perform the merge
    var mergedDoc = mergeWithOverride(oursDoc, theirsDoc);
    // For now, we'll use a simple approach: stringify with minimal formatting
    // In a more advanced version, we could preserve the original formatting
    var mergedContent = toml.stringify(mergedDoc);
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
    var _a = process.argv, baseFile = _a[2], oursFile = _a[3], theirsFile = _a[4];
    try {
        // Read TOML files
        var baseContent = fs.readFileSync(baseFile, "utf-8");
        var oursContent = fs.readFileSync(oursFile, "utf-8");
        var theirsContent = fs.readFileSync(theirsFile, "utf-8");
        var baseDoc = toml.parse(baseContent);
        var theirsDoc = toml.parse(theirsContent);
        // Git merge driver: %A (current branch) gets modified with %B (other branch) values
        // 1. Start with copy of ours_doc (%A - current branch)
        // 2. Every key from theirs_doc (%B - other branch) REPLACES key in result
        // 3. Keep keys in ours_doc that don't exist in theirs_doc
        // 4. Result written back to %A
        var mergedContent = mergeTomlPreservingFormat(oursContent, theirsDoc);
        // Write merged result back to ours_file
        fs.writeFileSync(oursFile, mergedContent, "utf-8");
        console.log("Git merge: All keys from ".concat(theirsFile, " (%B) replaced keys in ").concat(oursFile, " (%A), kept unique %A keys"));
        process.exit(0); // Indicate successful merge
    }
    catch (error) {
        console.error("Error during TOML merge: ".concat(error), error);
        process.exit(1);
    }
}
if (require.main === module) {
    main();
}
