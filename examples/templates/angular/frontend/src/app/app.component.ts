import { ChangeDetectionStrategy, Component, OnInit, signal } from "@angular/core";

@Component({
  selector: "app-root",
  template: `
    <main class="counter">
      <h1>Ring + Angular</h1>
      <p class="count">{{ count() }}</p>
      <div class="buttons">
        <button (click)="decrement()">- Decrement</button>
        <button (click)="increment()">+ Increment</button>
      </div>
    </main>
  `,
  changeDetection: ChangeDetectionStrategy.OnPush,
})
export class AppComponent implements OnInit {
  readonly count = signal(0);

  async ngOnInit(): Promise<void> {
    this.count.set(Number(await window.getInitialCount()));
  }

  async increment(): Promise<void> {
    this.count.set(Number(await window.increment()));
  }

  async decrement(): Promise<void> {
    this.count.set(Number(await window.decrement()));
  }
}
