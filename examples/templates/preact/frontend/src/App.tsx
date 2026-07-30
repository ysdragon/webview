import { useEffect, useState } from "preact/hooks";

export function App() {
  const [count, setCount] = useState(0);

  useEffect(() => {
    window.getInitialCount().then((n) => setCount(Number(n)));
  }, []);

  const increment = async () => setCount(Number(await window.increment()));
  const decrement = async () => setCount(Number(await window.decrement()));

  return (
    <main class="counter">
      <h1>Ring + Preact</h1>
      <p class="count">{count}</p>
      <div class="buttons">
        <button onClick={decrement}>- Decrement</button>
        <button onClick={increment}>+ Increment</button>
      </div>
    </main>
  );
}
