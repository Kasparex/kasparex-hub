import type { EntryContext } from "@remix-run/cloudflare-pages";

export function getLoadContext(
  context: { request: Request; env: any; waitUntil: (promise: Promise<any>) => void }
): EntryContext {
  return context as EntryContext;
}

