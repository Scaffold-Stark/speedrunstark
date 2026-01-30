"use client";

import { useState, useMemo } from "react";
import {
  LineChart,
  Line,
  XAxis,
  YAxis,
  CartesianGrid,
  Tooltip,
  Legend,
  ResponsiveContainer,
} from "recharts";
import { useVendorActivity, VendorActivityData } from "~~/hooks/scaffold-stark/useVendorActivity";

interface VendorActivityChartProps {
  className?: string;
}

const formatDate = (timestamp: number): string => {
  return new Date(timestamp).toLocaleDateString("en-US", {
    month: "short",
    day: "numeric",
    hour: "2-digit",
  });
};

const formatTooltipDate = (timestamp: number): string => {
  return new Date(timestamp).toLocaleString("en-US", {
    month: "short",
    day: "numeric",
    year: "numeric",
    hour: "2-digit",
    minute: "2-digit",
  });
};

const formatDateForInput = (date: Date): string => {
  return date.toISOString().slice(0, 16);
};

export const VendorActivityChart = ({ className = "" }: VendorActivityChartProps) => {
  // Default to last 7 days
  const [startDate, setStartDate] = useState<Date>(() => {
    const date = new Date();
    date.setDate(date.getDate() - 7);
    return date;
  });
  const [endDate, setEndDate] = useState<Date>(() => new Date());

  const { data, isLoading, error, refetch } = useVendorActivity({
    startTime: startDate.getTime(),
    endTime: endDate.getTime(),
  });

  // Transform data for the chart
  const chartData = useMemo(() => {
    return data.map((item: VendorActivityData) => ({
      ...item,
      formattedTime: formatDate(item.timestamp),
    }));
  }, [data]);

  const handleStartDateChange = (e: React.ChangeEvent<HTMLInputElement>) => {
    const newDate = new Date(e.target.value);
    if (!isNaN(newDate.getTime())) {
      setStartDate(newDate);
    }
  };

  const handleEndDateChange = (e: React.ChangeEvent<HTMLInputElement>) => {
    const newDate = new Date(e.target.value);
    if (!isNaN(newDate.getTime())) {
      setEndDate(newDate);
    }
  };

  const setPresetRange = (days: number) => {
    const end = new Date();
    const start = new Date();
    start.setDate(start.getDate() - days);
    setStartDate(start);
    setEndDate(end);
  };

  return (
    <div className={`bg-base-100 rounded-xl shadow-lg p-6 ${className}`}>
      <div className="flex flex-col gap-4">
        {/* Header */}
        <div className="flex flex-col sm:flex-row justify-between items-start sm:items-center gap-4">
          <h2 className="text-2xl font-bold">Vendor Buy/Sell Activity</h2>
          <button
            onClick={() => refetch()}
            disabled={isLoading}
            className="btn btn-sm btn-primary"
          >
            {isLoading ? "Loading..." : "Refresh"}
          </button>
        </div>

        {/* Date Range Controls */}
        <div className="flex flex-col lg:flex-row gap-4 items-start lg:items-end">
          {/* Date Inputs */}
          <div className="flex flex-col sm:flex-row gap-4">
            <div className="form-control">
              <label className="label">
                <span className="label-text">Start Date</span>
              </label>
              <input
                type="datetime-local"
                value={formatDateForInput(startDate)}
                onChange={handleStartDateChange}
                max={formatDateForInput(endDate)}
                className="input input-bordered input-sm w-full sm:w-auto"
              />
            </div>
            <div className="form-control">
              <label className="label">
                <span className="label-text">End Date</span>
              </label>
              <input
                type="datetime-local"
                value={formatDateForInput(endDate)}
                onChange={handleEndDateChange}
                min={formatDateForInput(startDate)}
                max={formatDateForInput(new Date())}
                className="input input-bordered input-sm w-full sm:w-auto"
              />
            </div>
          </div>

          {/* Preset Buttons */}
          <div className="flex flex-wrap gap-2">
            <button onClick={() => setPresetRange(1)} className="btn btn-xs btn-outline">
              24h
            </button>
            <button onClick={() => setPresetRange(7)} className="btn btn-xs btn-outline">
              7d
            </button>
            <button onClick={() => setPresetRange(30)} className="btn btn-xs btn-outline">
              30d
            </button>
            <button onClick={() => setPresetRange(90)} className="btn btn-xs btn-outline">
              90d
            </button>
          </div>
        </div>

        {/* Error State */}
        {error && (
          <div className="alert alert-error">
            <span>Error loading data: {error.message}</span>
          </div>
        )}

        {/* Loading State */}
        {isLoading && (
          <div className="flex justify-center items-center h-64">
            <span className="loading loading-spinner loading-lg"></span>
          </div>
        )}

        {/* Empty State */}
        {!isLoading && !error && chartData.length === 0 && (
          <div className="flex flex-col justify-center items-center h-64 text-base-content/60">
            <svg
              xmlns="http://www.w3.org/2000/svg"
              className="h-16 w-16 mb-4"
              fill="none"
              viewBox="0 0 24 24"
              stroke="currentColor"
            >
              <path
                strokeLinecap="round"
                strokeLinejoin="round"
                strokeWidth={1.5}
                d="M9 19v-6a2 2 0 00-2-2H5a2 2 0 00-2 2v6a2 2 0 002 2h2a2 2 0 002-2zm0 0V9a2 2 0 012-2h2a2 2 0 012 2v10m-6 0a2 2 0 002 2h2a2 2 0 002-2m0 0V5a2 2 0 012-2h2a2 2 0 012 2v14a2 2 0 01-2 2h-2a2 2 0 01-2-2z"
              />
            </svg>
            <p className="text-lg font-medium">No activity data available</p>
            <p className="text-sm">
              Connect your Auco Indexer to see buy/sell activity
            </p>
          </div>
        )}

        {/* Chart */}
        {!isLoading && !error && chartData.length > 0 && (
          <div className="h-80 w-full">
            <ResponsiveContainer width="100%" height="100%">
              <LineChart
                data={chartData}
                margin={{ top: 5, right: 30, left: 20, bottom: 5 }}
              >
                <CartesianGrid strokeDasharray="3 3" className="opacity-30" />
                <XAxis
                  dataKey="formattedTime"
                  tick={{ fontSize: 12 }}
                  tickLine={false}
                />
                <YAxis
                  tick={{ fontSize: 12 }}
                  tickLine={false}
                  axisLine={false}
                  tickFormatter={(value) => `${value}`}
                  label={{
                    value: "Tokens",
                    angle: -90,
                    position: "insideLeft",
                    style: { textAnchor: "middle" },
                  }}
                />
                <Tooltip
                  contentStyle={{
                    backgroundColor: "hsl(var(--b1))",
                    borderColor: "hsl(var(--bc) / 0.2)",
                    borderRadius: "0.5rem",
                  }}
                  labelFormatter={(_, payload) => {
                    if (payload && payload[0]) {
                      return formatTooltipDate(payload[0].payload.timestamp);
                    }
                    return "";
                  }}
                  formatter={(value, name) => {
                    const numValue = typeof value === "number" ? value : 0;
                    return [
                      `${numValue.toFixed(2)} tokens`,
                      name === "buyAmount" ? "Buy" : "Sell",
                    ];
                  }}
                />
                <Legend
                  formatter={(value) => (value === "buyAmount" ? "Buy" : "Sell")}
                />
                <Line
                  type="monotone"
                  dataKey="buyAmount"
                  stroke="#22c55e"
                  strokeWidth={2}
                  dot={false}
                  activeDot={{ r: 6 }}
                  name="buyAmount"
                />
                <Line
                  type="monotone"
                  dataKey="sellAmount"
                  stroke="#ef4444"
                  strokeWidth={2}
                  dot={false}
                  activeDot={{ r: 6 }}
                  name="sellAmount"
                />
              </LineChart>
            </ResponsiveContainer>
          </div>
        )}

        {/* Summary Stats */}
        {!isLoading && !error && chartData.length > 0 && (
          <div className="grid grid-cols-2 sm:grid-cols-4 gap-4 mt-4">
            <div className="stat bg-base-200 rounded-lg p-4">
              <div className="stat-title text-xs">Total Buy Volume</div>
              <div className="stat-value text-lg text-success">
                {chartData.reduce((sum: number, d: VendorActivityData & { formattedTime: string }) => sum + d.buyAmount, 0).toFixed(2)}
              </div>
            </div>
            <div className="stat bg-base-200 rounded-lg p-4">
              <div className="stat-title text-xs">Total Sell Volume</div>
              <div className="stat-value text-lg text-error">
                {chartData.reduce((sum: number, d: VendorActivityData & { formattedTime: string }) => sum + d.sellAmount, 0).toFixed(2)}
              </div>
            </div>
            <div className="stat bg-base-200 rounded-lg p-4">
              <div className="stat-title text-xs">Net Flow</div>
              <div className="stat-value text-lg">
                {(
                  chartData.reduce((sum: number, d: VendorActivityData & { formattedTime: string }) => sum + d.buyAmount, 0) -
                  chartData.reduce((sum: number, d: VendorActivityData & { formattedTime: string }) => sum + d.sellAmount, 0)
                ).toFixed(2)}
              </div>
            </div>
            <div className="stat bg-base-200 rounded-lg p-4">
              <div className="stat-title text-xs">Data Points</div>
              <div className="stat-value text-lg">{chartData.length}</div>
            </div>
          </div>
        )}
      </div>
    </div>
  );
};

export default VendorActivityChart;
