# Ring WebView Templates

Starter templates pairing a Ring WebView backend with a modern frontend
framework. Every frontend is TypeScript, built with **Vite** and bundled to a
**single HTML file** via `vite-plugin-singlefile`, so the backend can load it
with one `setHtml(read(...))` call.

| Template | Frontend | Entry |
|----------|----------|-------|
| [`react/`](react/) | React (vite `react-ts`) | `react/main.ring` |
| [`vue/`](vue/) | Vue 3 (vite `vue-ts`) | `vue/main.ring` |
| [`svelte/`](svelte/) | Svelte 5 (vite `svelte-ts`) | `svelte/main.ring` |
| [`angular/`](angular/) | Angular (vite + `@analogjs/vite-plugin-angular`) | `angular/main.ring` |
| [`preact/`](preact/) | Preact (vite `preact-ts`) | `preact/main.ring` |
| [`solid/`](solid/) | SolidJS (vite `solid-ts`) | `solid/main.ring` |
| [`lit/`](lit/) | Lit web components (vite `lit-ts`) | `lit/main.ring` |

Each template contains `main.ring` (backend) and `frontend/` (Vite project).

## Build & Run (same for every template)

```sh
cd <template>/frontend
bun install
bun run build
cd ..
ring main.ring
```

> Run `ring main.ring` from the template directory — it references
> `frontend/dist/index.html` relatively.

## What the demo shows

A counter: the buttons call Ring functions bound as `window.increment()` /
`window.decrement()` (each returns the new count), and the initial value comes
from `window.getInitialCount()`.
