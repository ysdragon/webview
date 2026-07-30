import { createSignal, onMount } from "solid-js";

export default function App() {
  const [count, setCount] = createSignal(0);

  onMount(async () => {
    setCount(Number(await window.getInitialCount()));
  });

  const increment = async () => setCount(Number(await window.increment()));
  const decrement = async () => setCount(Number(await window.decrement()));

  return (
    <main class="counter">
      <h1>Ring + SolidJS</h1>
      <p class="count">{count()}</p>
      <div class="buttons">
        <button onClick={decrement}>- Decrement</button>
        <button onClick={increment}>+ Increment</button>
      </div>
    </main>
  );
}
