import { createRequestHandler } from "@remix-run/cloudflare-pages";
import * as build from "../build/index.js";

export const onRequest = createRequestHandler({
  build,
  mode: process.env.NODE_ENV,
});

