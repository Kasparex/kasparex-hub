import { createRequestHandler } from "@remix-run/cloudflare-pages";
import * as build from "../build";
import { getLoadContext } from "../app/entry.server";

export const onRequest = createRequestHandler({
  build,
  getLoadContext,
  mode: process.env.NODE_ENV,
});

