import { createRequestHandler } from "@remix-run/cloudflare-pages";
import * as build from "../build/index.js";

const requestHandler = createRequestHandler({
  build: build as any,
  mode: (build as any).mode || "production",
});

export const onRequest: PagesFunction = async (context) => {
  // Handle Remix routes - Remix will handle routing and static assets correctly
  const response = await requestHandler(context);
  
  // Ensure Content-Type header is set correctly for HTML responses
  const contentType = response.headers.get("Content-Type");
  if (contentType && contentType.includes("text/html")) {
    // Clone response to modify headers
    const newHeaders = new Headers(response.headers);
    newHeaders.set("Content-Type", "text/html; charset=UTF-8");
    newHeaders.set("X-Content-Type-Options", "nosniff");
    
    return new Response(response.body, {
      status: response.status,
      statusText: response.statusText,
      headers: newHeaders,
    });
  }
  
  // For non-HTML responses (like CSS, JS, images), return as-is
  return response;
};

