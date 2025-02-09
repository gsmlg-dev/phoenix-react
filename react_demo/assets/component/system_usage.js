import React from "react";


export function Component({ data }) {
  data = data || [];

  return (
    <table className="table table-primary-border table-animate-row" border={1}>
      <thead>
        <tr>
          <th>Time</th>
          <th className="text-right">CPU Usage</th>
          <th className="text-right">Memory Used</th>
        </tr>
      </thead>
      <tbody>
        {data.map((item, index) => (
          <tr 
            key={`t-${item.date}`}
            id={`ts-${new Date(item.date).getTime()}`}
          >
            <td>
              <time>{new Date(item.date).toLocaleString()}</time>
            </td>
            <td className="text-right">
              <span>{item.cpu.toFixed(2)}</span>
              <span className="select-none">%</span>
            </td>
            <td className="text-right">
              <span>{item.mem.toFixed(3)}</span>
              <span className="select-none">MiB</span>
            </td>
          </tr>
        ))}
      </tbody>
    </table>
  );
}
