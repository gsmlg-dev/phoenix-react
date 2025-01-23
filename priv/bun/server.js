import { serve, sleep, readableStreamToJSON } from 'bun';
import { renderToString } from 'react-dom/server';
import { join  } from 'path';

const { COMPONENT_BASE, BUN_ENV } = process.env;

const isDev = BUN_ENV === 'development';

const server = serve({
  development: isDev,
  async fetch(req) {
    try {
      if (isDev) {
        console.log('fetch', req.method, req.url);
      }
      const { url } = req;
      const uri = new URL(url);
      const { pathname } = uri;
      if (pathname.startsWith('/stop')) {
        setImmediate(() => server.stop());
        return new Response('{"message":"ok"}', {
          headers: {
            "Content-Type": "application/json",
          },
        });
      }
      if (pathname.startsWith('/component/')) {
        const props = await readableStreamToJSON(req.body);
        const fileName = pathname.replace(/^\/component\//, '');
        const componentFile = join(COMPONENT_BASE, fileName);
        const { Component } = await import(componentFile);
        const html = renderToString(<Component {...props} />);
        return new Response(html, {
          headers: {
            "Content-Type": "text/html",
          },
        });
      }
    } catch(error) {
      throw error;
    }
  },
  error(error) {
    const html = `
    <div role="alert" class="alert alert-error">
      <div>
        <div class="font-bold">${error}</div>
        <pre>${error.stack}</pre>
      </div>
    </div>
    `;
    return new Response(html, {
      status: 500,
      headers: {
        "Content-Type": "text/html",
      },
    });
  },
});

console.log(`Server started at http://localhost:${server.port}`);
console.log(`COMPONENT_BASE`, COMPONENT_BASE);
console.log(`BUN_ENV`, BUN_ENV);

const shutdown = async (signal) => {
  console.log(`\nReceived ${signal}. Cleaning up...`);

  await server.stop();

  console.log("Cleanup done. Exiting.");
  process.exit(0);
};

process.on('SIGINT', () => {
  shutdown("SIGINT");
});

process.on('SIGTERM', () => {
  shutdown("SIGTERM");
});

process.on("exit", () => {
  console.log("Parent process exited. Shutting down server...");
  shutdown("exit");
});

process.stdin.on("close", () => {
  console.log("Parent process closed stdin. Exiting...");
  shutdown("close");
});
