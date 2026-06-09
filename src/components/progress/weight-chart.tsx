"use client";

import {
  LineChart,
  Line,
  XAxis,
  YAxis,
  CartesianGrid,
  Tooltip,
  ResponsiveContainer,
} from "recharts";
import { format } from "date-fns";

interface WeightChartProps {
  data: { log_date: string; weight_kg: number }[];
}

export function WeightChart({ data }: WeightChartProps) {
  const chartData = data.map((d) => ({
    date: format(new Date(d.log_date), "MMM d"),
    weight: d.weight_kg,
  }));

  if (chartData.length === 0) {
    return (
      <div className="card flex h-64 items-center justify-center text-slate-500">
        Log your weight to see trends
      </div>
    );
  }

  return (
    <div className="card">
      <h3 className="mb-4 text-lg font-semibold text-white">Weight Over Time</h3>
      <ResponsiveContainer width="100%" height={250}>
        <LineChart data={chartData}>
          <CartesianGrid strokeDasharray="3 3" stroke="#334155" />
          <XAxis dataKey="date" stroke="#94A3B8" fontSize={12} />
          <YAxis stroke="#94A3B8" fontSize={12} domain={["auto", "auto"]} />
          <Tooltip
            contentStyle={{
              background: "#1E293B",
              border: "1px solid #334155",
              borderRadius: "12px",
            }}
            labelStyle={{ color: "#94A3B8" }}
          />
          <Line
            type="monotone"
            dataKey="weight"
            stroke="#1D9E75"
            strokeWidth={2}
            dot={{ fill: "#1D9E75", r: 4 }}
            activeDot={{ r: 6 }}
          />
        </LineChart>
      </ResponsiveContainer>
    </div>
  );
}
