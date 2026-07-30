<script lang="ts">
  import { onMount } from "svelte";

  let count = $state(0);

  onMount(async () => {
    count = Number(await window.getInitialCount());
  });

  async function increment() {
    count = Number(await window.increment());
  }

  async function decrement() {
    count = Number(await window.decrement());
  }
</script>

<main class="counter">
  <h1>Ring + Svelte</h1>
  <p class="count">{count}</p>
  <div class="buttons">
    <button onclick={decrement}>- Decrement</button>
    <button onclick={increment}>+ Increment</button>
  </div>
</main>
