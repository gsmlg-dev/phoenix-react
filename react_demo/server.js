import { serve, sleep, readableStreamToJSON } from 'bun';
import { renderToString } from 'react-dom/server';
import { join  } from 'path';

const { COMPONENT_PATH } = process.env;

const server = serve({
  async fetch(req) {
    try {
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
        const componentFile = join(COMPONENT_PATH, fileName);
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
