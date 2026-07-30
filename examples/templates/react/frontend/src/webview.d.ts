/// <reference types="vite/client" />

declare global {
  interface Window {
    increment(): Promise<number>;
    decrement(): Promise<number>;
    getInitialCount(): Promise<number>;
  }
}

export {};
