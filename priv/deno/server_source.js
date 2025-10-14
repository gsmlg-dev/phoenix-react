import { serve } from "https://deno.land/std@0.208.0/http/server.ts";
import React from "npm:react";
import { renderToReadableStream, renderToString, renderToStaticMarkup } from "npm:react-dom/server";

const __comMap = {};

import { Component as __component_0 } from "./jsx_components/markdown.jsx";
__comMap["markdown"] = __component_0;

import { Component as __component_1 } from "./jsx_components/tab.jsx";
__comMap["tab"] = __component_1;


const { COMPONENT_BASE, DENO_ENV } = Deno.env.toObject();

const isDev = DENO_ENV === 'development';

const port = parseInt(Deno.env.get("PORT") || "5226");

const handler = async (req) => {
  try {
    let bodyStream = req.body;
    if (isDev) {
      const bodyText = await req.text();
      console.log('Request: ', req.method, req.url, bodyText);
      bodyStream = new ReadableStream({
        start(controller) {
          controller.enqueue(new TextEncoder().encode(bodyText));
          controller.close();
        }
      });
    }
    const { url } = req;
    const uri = new URL(url);
    const { pathname } = uri;

    // Security: Validate pathname to prevent path traversal
    if (pathname.includes('..') || pathname.includes('\\')) {
      return new Response('Invalid path', { status: 400 });
    }

    if (pathname.startsWith('/stop')) {
      return new Response('{"message":"ok"}', {
        headers: {
          "Content-Type": "application/json",
        },
      });
    }

    if (pathname.startsWith('/render_to_static_markup/')) {
      const props = await req.json();
      const fileName = pathname.replace(/^\/render_to_static_markup\//, '');
      
      // Security: Validate component name
      if (!/^[a-zA-Z0-9_-]+$/.test(fileName)) {
        return new Response('Invalid component name', { status: 400 });
      }
      
      const Component = __comMap[fileName];
      if (!Component) {
        return new Response(`Not Found, component not found.`, {
          status: 404,
          headers: {
            "Content-Type": "text/html",
          },
        });
      }
      const jsxNode = React.createElement(Component, props);
      const html = renderToStaticMarkup(jsxNode);
      return new Response(html, {
        headers: {
          "Content-Type": "text/html",
        },
      });
    }

    if (pathname.startsWith('/render_to_string/')) {
      const props = await req.json();
      const fileName = pathname.replace(/^\/render_to_string\//, '');
      
      // Security: Validate component name
      if (!/^[a-zA-Z0-9_-]+$/.test(fileName)) {
        return new Response('Invalid component name', { status: 400 });
      }
      
      const Component = __comMap[fileName];
      const jsxNode = React.createElement(Component, props);
      const html = renderToString(jsxNode);
      return new Response(html, {
        headers: {
          "Content-Type": "text/html",
        },
      });
    }

    if (pathname.startsWith('/render_to_readable_stream/')) {
      const props = await req.json();
      const fileName = pathname.replace(/^\/render_to_readable_stream\//, '');
      
      // Security: Validate component name
      if (!/^[a-zA-Z0-9_-]+$/.test(fileName)) {
        return new Response('Invalid component name', { status: 400 });
      }
      
      const Component = __comMap[fileName];
      const jsxNode = React.createElement(Component, props);
      const stream = await renderToReadableStream(jsxNode);
      return new Response(stream, {
        headers: {
          "Content-Type": "text/html",
        },
      });
    }

    return new Response(`Not Found, not matched request.`, {
      status: 404,
      headers: {
        "Content-Type": "text/html",
      },
    });
  } catch(error) {
    const html = `
    <div role="alert" class="alert alert-error">
      <div>
        <div class="font-bold">${escapeHtml(error.toString())}</div>
        <pre style="white-space: pre-wrap;">${escapeHtml(error.stack || '')}</pre>
      </div>
    </div>
    `;
    return new Response(html, {
      status: 500,
      headers: {
        "Content-Type": "text/html",
      },
    });
  }
};

function escapeHtml(unsafe) {
  return unsafe
    .replace(/&/g, "&amp;")
    .replace(/</g, "&lt;")
    .replace(/>/g, "&gt;")
    .replace(/"/g, "&quot;")
    .replace(/'/g, "&#039;");
}

console.log(`Server started at http://localhost:${port}`);
console.log(`COMPONENT_BASE`, COMPONENT_BASE);
console.log(`DENO_ENV`, DENO_ENV);

const ppid = Deno.pid;
const parentCheckInterval = parseInt(Deno.env.get("PARENT_CHECK_INTERVAL") || "5000");

const checkParentInterval = setInterval(() => {
  try {
    // Enhanced validation: ensure PPID is valid and different from current process
    if (ppid && ppid > 1 && ppid !== Deno.pid) {
      Deno.kill(ppid, "0");
    } else {
      console.log("Invalid PPID detected. Shutting down server...");
      clearInterval(checkParentInterval);
      Deno.exit(0);
    }
  } catch (e) {
    console.log("Parent process exited. Shutting down server...");
    clearInterval(checkParentInterval);
    Deno.exit(0);
  }
}, parentCheckInterval);

const shutdown = async (signal) => {
  console.log(`\nReceived ${signal}. Cleaning up...`);
  clearInterval(checkParentInterval);
  console.log("Cleanup done. Exiting.");
  Deno.exit(0);
};

Deno.addSignalListener("SIGINT", () => {
  shutdown("SIGINT");
});

Deno.addSignalListener("SIGTERM", () => {
  shutdown("SIGTERM");
});

await serve(handler, { port });