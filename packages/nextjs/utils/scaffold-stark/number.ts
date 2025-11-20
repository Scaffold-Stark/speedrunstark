import { parseParamWithType } from "./contract";

/**
 * Normalize mixed Starknet `u256` outputs (raw structs, arrays, or bigint)
 * into a `bigint`. Returns `undefined` when parsing fails.
 */
export const decodeUint256Value = (value: unknown): bigint | undefined => {
  if (!value) {
    return undefined;
  }

  const rawValue = Array.isArray(value) ? value[0] : value;

  if (!rawValue) {
    return undefined;
  }

  if (typeof rawValue === "bigint") {
    return rawValue;
  }

  try {
    return parseParamWithType("core::integer::u256", rawValue, true) as bigint;
  } catch (error) {
    console.error("decodeUint256Value failed:", error);
    return undefined;
  }
};
