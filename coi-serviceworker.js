/* coi-serviceworker v0.1.7 - https://github.com/gzuidhof/coi-serviceworker */
self.addEventListener("install", function(event) {
  self.skipWaiting();
});

self.addEventListener("activate", function(event) {
  event.waitUntil(self.clients.claim());
});

async function handleFetch(request) {
  if (request.cache === "only-if-cached" && request.mode !== "same-origin") {
    return;
  }

  const response = await fetch(request);
  if (response.status === 0) {
    return response;
  }

  const newHeaders = new Headers(response.headers);
  newHeaders.set("Cross-Origin-Opener-Policy", "same-origin");
  newHeaders.set("Cross-Origin-Embedder-Policy", "require-corp");

  return new Response(response.body, {
    status: response.status,
    statusText: response.statusText,
    headers: newHeaders,
  });
}

self.addEventListener("fetch", function(event) {
  event.respondWith(handleFetch(event.request));
});
