import { createRequestHandler } from "@remix-run/cloudflare-pages";
import * as build from "../build/index.js";

const requestHandler = createRequestHandler({
  build: build as any,
  mode: (build as any).mode || "production",
});

export const onRequest: PagesFunction = async (context) => {
  const response = await requestHandler(context);
  
  // Ensure Content-Type header is set correctly for HTML responses
  const contentType = response.headers.get("Content-Type");
  const url = new URL(context.request.url);
  const isStaticAsset = url.pathname.match(/\.(js|css|json|png|jpg|jpeg|gif|svg|ico|woff|woff2|ttf|eot)$/i);
  
  if (!isStaticAsset) {
    // For HTML responses, ensure Content-Type is set correctly
    if (!contentType || contentType.includes("text/html")) {
      response.headers.set("Content-Type", "text/html; charset=UTF-8");
    }
    // Add security headers
    response.headers.set("X-Content-Type-Options", "nosniff");
  }
  
  return response;
};

