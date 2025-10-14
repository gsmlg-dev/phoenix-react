export const Component = (props = {}) => {
  return React.createElement('div', { className: 'test-component' }, `Hello ${props.name || 'World'}!`);
};
