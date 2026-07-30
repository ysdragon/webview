import { useEffect, useState } from "react";

export default function App() {
  const [count, setCount] = useState(0);

  useEffect(() => {
    window.getInitialCount().then((n) => setCount(Number(n)));
  }, []);

  const increment = async () => setCount(Number(await window.increment()));
  const decrement = async () => setCount(Number(await window.decrement()));

  return (
    <main className="counter">
      <h1>Ring + React</h1>
      <p className="count">{count}</p>
      <div className="buttons">
        <button onClick={decrement}>- Decrement</button>
        <button onClick={increment}>+ Increment</button>
      </div>
    </main>
  );
}
