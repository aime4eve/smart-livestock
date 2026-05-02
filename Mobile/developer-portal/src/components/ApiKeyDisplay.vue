<script setup>
import { computed } from 'vue';

const props = defineProps({
  keyPrefix: { type: String, required: true },
  keySuffix: { type: String, required: true },
});

const obfuscated = computed(() => {
  return `${props.keyPrefix}****${props.keySuffix}`;
});
</script>

<template>
  <code class="api-key-display">{{ obfuscated }}</code>
</template>

<style scoped>
.api-key-display {
  font-family: monospace;
  font-size: 13px;
  background: #f5f5f5;
  padding: 2px 8px;
  border-radius: 4px;
  color: #333;
}
</style>
