import * as React from 'react';


export default (props = {}) => {
  return (
    <div>
      <h3>Markdown source:</h3>
      <pre>
        {props.data ?? 'N/A'}
      </pre>
    </div>
  );
}
