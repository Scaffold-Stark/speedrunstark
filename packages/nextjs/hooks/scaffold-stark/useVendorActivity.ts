"use client";

import { useState, useEffect, useCallback } from "react";

export type VendorActivityType = "buy" | "sell";

export interface VendorActivityEvent {
  timestamp: number;
  type: VendorActivityType;
  amount: bigint;
  strkAmount: bigint;
  transactionHash: string;
  address: string;
}

export interface VendorActivityData {
  timestamp: number;
  buyAmount: number;
  sellAmount: number;
}

export interface UseVendorActivityParams {
  startTime?: number;
  endTime?: number;
  enabled?: boolean;
}

export interface UseVendorActivityReturn {
  data: VendorActivityData[];
  rawEvents: VendorActivityEvent[];
  isLoading: boolean;
  error: Error | null;
  refetch: () => Promise<void>;
}

/**
 * Skeleton hook for fetching vendor buy/sell activity from the Auco Indexer.
 *
 * This hook is designed to be integrated with your Auco Indexer backend.
 * Replace the TODO sections with actual API calls to your indexer endpoints.
 *
 * @param params - Configuration parameters
 * @param params.startTime - Start timestamp (Unix ms) for the query range
 * @param params.endTime - End timestamp (Unix ms) for the query range
 * @param params.enabled - Whether the hook should fetch data (default: true)
 *
 * @example
 * ```tsx
 * const { data, isLoading, error } = useVendorActivity({
 *   startTime: Date.now() - 7 * 24 * 60 * 60 * 1000, // 7 days ago
 *   endTime: Date.now(),
 * });
 * ```
 */
export const useVendorActivity = ({
  startTime,
  endTime,
  enabled = true,
}: UseVendorActivityParams = {}): UseVendorActivityReturn => {
  const [rawEvents, setRawEvents] = useState<VendorActivityEvent[]>([]);
  const [isLoading, setIsLoading] = useState(false);
  const [error, setError] = useState<Error | null>(null);

  const fetchActivity = useCallback(async () => {
    if (!enabled) return;

    setIsLoading(true);
    setError(null);

    try {
      // TODO: Replace with actual Auco Indexer API call
      // Example endpoint structure:
      // const response = await fetch(
      //   `${AUCO_INDEXER_URL}/api/vendor-events?startTime=${startTime}&endTime=${endTime}`
      // );
      // const events = await response.json();

      // Placeholder: Return empty array until indexer is integrated
      const events: VendorActivityEvent[] = [];

      // TODO: Transform API response to VendorActivityEvent[]
      // Example transformation:
      // const events = apiResponse.map((event) => ({
      //   timestamp: event.block_timestamp * 1000,
      //   type: event.event_name === "BuyTokens" ? "buy" : "sell",
      //   amount: BigInt(event.tokens_amount),
      //   strkAmount: BigInt(event.strk_amount),
      //   transactionHash: event.transaction_hash,
      //   address: event.buyer || event.seller,
      // }));

      setRawEvents(events);
    } catch (err) {
      setError(err instanceof Error ? err : new Error("Failed to fetch vendor activity"));
    } finally {
      setIsLoading(false);
    }
  }, [startTime, endTime, enabled]);

  useEffect(() => {
    fetchActivity();
  }, [fetchActivity]);

  // Aggregate events into chart-friendly data grouped by time intervals
  const data: VendorActivityData[] = aggregateActivityData(rawEvents, startTime, endTime);

  return {
    data,
    rawEvents,
    isLoading,
    error,
    refetch: fetchActivity,
  };
};

/**
 * Aggregates raw events into time-bucketed data for charting.
 * Groups events by hour and sums up buy/sell amounts.
 */
function aggregateActivityData(
  events: VendorActivityEvent[],
  startTime?: number,
  endTime?: number
): VendorActivityData[] {
  if (events.length === 0) return [];

  // Filter events within time range
  const filteredEvents = events.filter((event) => {
    if (startTime && event.timestamp < startTime) return false;
    if (endTime && event.timestamp > endTime) return false;
    return true;
  });

  // Group by hour
  const hourlyBuckets = new Map<number, VendorActivityData>();

  filteredEvents.forEach((event) => {
    const hourTimestamp = Math.floor(event.timestamp / (60 * 60 * 1000)) * (60 * 60 * 1000);

    if (!hourlyBuckets.has(hourTimestamp)) {
      hourlyBuckets.set(hourTimestamp, {
        timestamp: hourTimestamp,
        buyAmount: 0,
        sellAmount: 0,
      });
    }

    const bucket = hourlyBuckets.get(hourTimestamp)!;
    const amountInTokens = Number(event.amount) / 1e18;

    if (event.type === "buy") {
      bucket.buyAmount += amountInTokens;
    } else {
      bucket.sellAmount += amountInTokens;
    }
  });

  // Sort by timestamp and return as array
  return Array.from(hourlyBuckets.values()).sort((a, b) => a.timestamp - b.timestamp);
}

export default useVendorActivity;
