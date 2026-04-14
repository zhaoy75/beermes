<template>
  <ThemeProvider>
    <SidebarProvider>
      <RouterView />
    </SidebarProvider>
  </ThemeProvider>
</template>

<script setup lang="ts">
import ThemeProvider from './components/layout/ThemeProvider.vue'
import SidebarProvider from './components/layout/SidebarProvider.vue'
import 'vue3-toastify/dist/index.css'

import { onBeforeUnmount, onMounted } from 'vue'
import { bindGlobalDateInputPicker } from './lib/dateInputPicker'
import { useAuthStore } from './stores/auth'

const auth = useAuthStore()
let releaseDateInputPicker: null | (() => void) = null

onMounted(() => {
  auth.bootstrap()
  releaseDateInputPicker = bindGlobalDateInputPicker()
})

onBeforeUnmount(() => {
  releaseDateInputPicker?.()
  releaseDateInputPicker = null
})
</script>
