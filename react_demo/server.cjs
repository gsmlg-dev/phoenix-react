import { readableStreamToText } from 'bun';

import { renderToString, renderToReadableStream } from 'react-dom/server';


// const base = './priv/react/dev'

const base = './assets/component';
// import { Component as Markdown } from './priv/react/dev/markdown';
// import { Component as SystemUsage } from './priv/react/dev/system_usage';
// import { Component as SystemUsage } from './assets/component/system_usage';
const { Component: Markdown } = require(`${base}/markdown`);
const { Component: SystemUsage } = require(`${base}/system_usage`);

let Component;

Component = Markdown
Component = SystemUsage


const jsxNode = <Component />

// console.log(jsxNode);

const str = renderToString(jsxNode);

const stream = await renderToReadableStream(jsxNode);

// const str = await readableStreamToText(stream);

console.log(str);
