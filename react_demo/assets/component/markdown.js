import * as React from 'react';
import Markdown from 'react-markdown';
import remarkGfm from 'remark-gfm';
import MarkdownPreview from '@uiw/react-markdown-preview';

import {Prism as SyntaxHighlighter} from 'react-syntax-highlighter';
import {dark} from 'react-syntax-highlighter/dist/esm/styles/prism';

export const Component = (props = {}) => {

  // return (
  //   <MarkdownPreview
  //     source={props.data}
  //     className=""
  //     style={{ 
  //       color: 'var(--color-base-content)',
  //       backgroundColor: 'var(--color-base-200)',
  //       whiteSpace: 'pre-wrap',
  //       padding: '1rem',
  //     }}
  //   />
  // );
  return (
    <Markdown 
      className="markdown-body"
      remarkPlugins={[remarkGfm]}
      components={{
        code(props) {
          const {children, className, node, ...rest} = props
          const match = /language-(\w+)/.exec(className || '')
          return match ? (
            <SyntaxHighlighter
              {...rest}
              PreTag="div"
              children={String(children).replace(/\n$/, '')}
              language={match[1]}
              style={dark}
            />
          ) : (
            <code {...rest} className={className}>
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
