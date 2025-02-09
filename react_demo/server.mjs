// import { readableStreamToText } from 'bun';

import { renderToString } from 'react-dom/server';

import { jsx } from "react/jsx-runtime";
import { jsxDEV } from "react/jsx-dev-runtime";

let jsxRuntime;
jsxRuntime = jsx;
jsxRuntime = jsxDEV;

const base = './priv/react/dev'

// const base = './assets/component';
import { Component as Markdown } from './priv/react/dev/markdown.js';
import { Component as SystemUsage } from './priv/react/dev/system_usage.js';
// import { Component as SystemUsage } from './assets/component/system_usage.js';

let Component;

Component = Markdown
Component = SystemUsage

const jsxNode = jsxRuntime(Component, {}, null);

// console.log(jsxNode);

const str = renderToString(jsxNode);

// const stream = await renderToReadableStream(jsxNode);

// const str = await readableStreamToText(stream);

console.log(str);
