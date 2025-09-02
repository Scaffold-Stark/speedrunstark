#!/usr/bin/env python3
import sys
import copy
import tomlkit

def merge_with_override(target_doc: tomlkit.TOMLDocument, source_doc: tomlkit.TOMLDocument) -> tomlkit.TOMLDocument:
    """Git merge: Every key from source (%B) REPLACES matching key in target (%A). Keep unique target keys."""
    for key, value in source_doc.items():
        if key not in target_doc:
            # Key doesn't exist in target - add it
            target_doc[key] = value
        elif isinstance(target_doc[key], tomlkit.items.Table) and isinstance(value, tomlkit.items.Table):
            # Both are tables - recursively merge with override
            target_doc[key] = merge_table_with_override(target_doc[key], value)
        else:
            # Key exists - OVERRIDE with source value
            target_doc[key] = value
    return target_doc

def merge_table_with_override(target_table: tomlkit.items.Table, source_table: tomlkit.items.Table) -> tomlkit.items.Table:
    """Git merge tables: Every key from source table REPLACES matching key in target table."""
    for key, value in source_table.items():
        if key not in target_table:
            # Key doesn't exist in target table - add it
            target_table[key] = value
        elif isinstance(target_table[key], tomlkit.items.Table) and isinstance(value, tomlkit.items.Table):
            # Both are tables - recursively merge with override
            target_table[key] = merge_table_with_override(target_table[key], value)
        else:
            # Key exists - OVERRIDE with source value
            target_table[key] = value
    return target_table

def main():
    if len(sys.argv) != 4:
        print("Usage: merge-toml.py <base> <ours> <theirs>")
        sys.exit(1)

    base_file, ours_file, theirs_file = sys.argv[1:4]

    try:
        # Read TOML files using tomlkit to preserve comments and formatting
        with open(base_file, "r", encoding="utf-8") as f:
            base_doc = tomlkit.load(f)
        with open(ours_file, "r", encoding="utf-8") as f:
            ours_doc = tomlkit.load(f)
        with open(theirs_file, "r", encoding="utf-8") as f:
            theirs_doc = tomlkit.load(f)

        # Git merge driver: %A (current branch) gets modified with %B (other branch) values  
        # 1. Start with copy of ours_doc (%A - current branch) 
        # 2. Every key from theirs_doc (%B - other branch) REPLACES key in result
        # 3. Keep keys in ours_doc that don't exist in theirs_doc  
        # 4. Result written back to %A
        result_doc = copy.deepcopy(ours_doc)
        result_doc = merge_with_override(result_doc, theirs_doc)

        # Write merged result back to ours_file, preserving formatting
        with open(ours_file, "w", encoding="utf-8") as f:
            tomlkit.dump(result_doc, f)

        print(f"Git merge: All keys from {theirs_file} (%B) replaced keys in {ours_file} (%A), kept unique %A keys")
        sys.exit(0)  # Indicate successful merge

    except Exception as e:
        print(f"Error during TOML merge: {e}", file=sys.stderr)
        sys.exit(1)

if __name__ == "__main__":
    main()