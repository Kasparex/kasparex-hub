import { createRequestHandler } from "@remix-run/cloudflare-pages";
import * as build from "../build";

export const onRequest = createRequestHandler({
  build,
  mode: process.env.NODE_ENV,
});

