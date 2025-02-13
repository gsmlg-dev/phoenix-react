import React from "react";
import MDEditor from '@uiw/react-md-editor';
import "@uiw/react-md-editor/markdown-editor.css";
import "@uiw/react-markdown-preview/markdown.css";

export function Component({ data = "", setData }) {
  const { content } = data;

  return (
    <div className="container">
      <h1>Live Form</h1>
      <form>
        <MDEditor
          value={content}
          onChange={(value) => setData({ content: value })}
        />
        <br />
        <br />
        <MDEditor.Markdown 
          source={content}
          style={{ 
            whiteSpace: 'pre-wrap',
            padding: '1rem',
          }}
        />
      </form>
    </div>
  );
}
