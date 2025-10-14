import React from 'react';

export const Component = (props = {}) => {
  return <div className="test-component">Hello {props.name || 'World'}!</div>;
};
