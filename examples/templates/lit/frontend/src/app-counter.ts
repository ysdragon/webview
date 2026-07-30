import { LitElement, html } from "lit";
import { customElement, state } from "lit/decorators.js";
import "./index.css";

@customElement("app-counter")
export class AppCounter extends LitElement {
  @state()
  private count = 0;

  async connectedCallback() {
    super.connectedCallback();
    this.count = Number(await window.getInitialCount());
  }

  private async increment() {
    this.count = Number(await window.increment());
  }

  private async decrement() {
    this.count = Number(await window.decrement());
  }

  // Render into light DOM so the global stylesheet applies (no shadow root).
  protected createRenderRoot() {
    return this;
  }

  render() {
    return html`
      <main class="counter">
        <h1>Ring + Lit</h1>
        <p class="count">${this.count}</p>
        <div class="buttons">
          <button @click=${this.decrement}>- Decrement</button>
          <button @click=${this.increment}>+ Increment</button>
        </div>
      </main>
    `;
  }
}

declare global {
  interface HTMLElementTagNameMap {
    "app-counter": AppCounter;
  }
}
