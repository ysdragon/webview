# Ring WebView + Lit Template

Lit (TypeScript) frontend bundled to a single HTML file with Vite +
`vite-plugin-singlefile`, loaded by a Ring WebView backend.

> Lit builds standard Web Components. The `<app-counter>` element renders into
> the light DOM (see `createRenderRoot()` in `src/app-counter.ts`) so the
> global stylesheet applies.

## Prerequisites

- **Ring** ≥ 1.27 with the webview library installed (see repo root README)
- **bun** ≥ 1.0

## Build & Run

```sh
cd frontend
bun install
bun run build
cd ..
ring main.ring
```

> Run `ring main.ring` from this directory — it loads `frontend/dist/index.html`
> via a relative path.

## How it works

- `main.ring` binds `increment`, `decrement` and `getInitialCount` and loads
  the built single-file HTML with `setHtml(read(...))`.
- The Lit app calls `window.increment()` / `window.decrement()` (each
  returns the new count) and `window.getInitialCount()` on mount.
- Declarations for these globals live in `frontend/src/webview.d.ts`.
- Editing the frontend? Re-run `bun run build` inside `frontend/`, then re-run
  `ring main.ring`.
