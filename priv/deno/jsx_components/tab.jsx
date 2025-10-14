import * as React from 'react';

export const Component = ({ tabs }) => {
  let list = tabs ?? [];
  return (
    <div className="tab">
      {list.map((tab, index) => (
        <div className="tab-item">
          {tab}
        </div>
      ))}
    </div>
  )
}
