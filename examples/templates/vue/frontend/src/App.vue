<script setup lang="ts">
import { onMounted, ref } from "vue";

const count = ref(0);

onMounted(async () => {
  count.value = Number(await window.getInitialCount());
});

async function increment() {
  count.value = Number(await window.increment());
}

async function decrement() {
  count.value = Number(await window.decrement());
}
</script>

<template>
  <main class="counter">
    <h1>Ring + Vue</h1>
    <p class="count">{{ count }}</p>
    <div class="buttons">
      <button @click="decrement">- Decrement</button>
      <button @click="increment">+ Increment</button>
    </div>
  </main>
</template>
