import './assets/main.css'
// Import Swiper styles
import 'swiper/css'
import 'swiper/css/navigation'
import 'swiper/css/pagination'
import 'jsvectormap/dist/jsvectormap.css'
import 'flatpickr/dist/flatpickr.css'
import { createPinia } from 'pinia'
import piniaPersist from 'pinia-plugin-persistedstate'
import Toast from 'vue3-toastify';
import 'vue3-toastify/dist/index.css';


import { createApp } from 'vue'
import App from './App.vue'
import router from './router'
import VueApexCharts from 'vue3-apexcharts'
import i18n from './i18n'


const pinia = createPinia()
pinia.use(piniaPersist)

const app = createApp(App)

app.use(pinia)
app.use(router)
app.use(VueApexCharts)
app.use(i18n)
app.use(Toast, {
    position: 'bottom-center',
    autoClose: 3000,
    transition: 'fade',
    toastClassName: 'rounded-md shadow-md font-medium', // Tailwind
    bodyClassName: 'text-sm',
    progressClassName: 'bg-white h-1',
  })

app.mount('#app')
