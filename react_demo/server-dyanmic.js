import { readableStreamToText } from 'bun';

import { renderToString, renderToReadableStream } from 'react-dom/server';

import { jsx } from "react/jsx-runtime";
import { jsxDEV } from "react/jsx-dev-runtime";

let jsxRuntime;
jsxRuntime = jsx;
jsxRuntime = jsxDEV;

const base = './priv/react/dev'

// const base = './assets/component';
const { Component: Markdown } = await import(`${base}/markdown`);
const { Component: SystemUsage } = await import(`${base}/system_usage`);

let Component;

Component = Markdown
Component = SystemUsage

const jsxNode = jsxRuntime(Component, {}, null);

// console.log(jsxNode);

// const str = renderToString(jsxNode);

const stream = await renderToReadableStream(jsxNode);

const str = await readableStreamToText(stream);

console.log(str);
