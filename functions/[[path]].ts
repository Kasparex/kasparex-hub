import { createRequestHandler } from "@remix-run/cloudflare-pages";
import * as build from "../build/index.js";

const requestHandler = createRequestHandler({
  build: build as any,
  mode: (build as any).mode || "production",
});

export const onRequest: PagesFunction = async (context) => {
  const response = await requestHandler(context);
  
  // Ensure Content-Type header is set correctly for HTML responses
  // Only modify if it's not a static asset
  const url = new URL(context.request.url);
  const isStaticAsset = url.pathname.match(/\.(js|css|json|png|jpg|jpeg|gif|svg|ico|woff|woff2|ttf|eot|webp|avif)$/i);
  
  if (!isStaticAsset) {
    const contentType = response.headers.get("Content-Type");
    if (!contentType || contentType.includes("text/html")) {
      response.headers.set("Content-Type", "text/html; charset=UTF-8");
    }
    response.headers.set("X-Content-Type-Options", "nosniff");
  }
  
  return response;
};

