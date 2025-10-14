import * as React from 'react';
import Markdown from 'react-markdown';
import remarkGfm from 'remark-gfm';

export const Component = (props = {}) => {
  return (
    <Markdown 
      className="markdown-body"
      remarkPlugins={[remarkGfm]}
      components={{
        code(props) {
          const {children, className, node, ...rest} = props
          return (
            <code {...rest} className={className || ''}>
              {children}
            </code>
          )
        }
      }}
    >
      {props.data}
    </Markdown>
  );
}
