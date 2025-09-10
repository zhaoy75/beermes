import { createI18n } from 'vue-i18n'
import en from './locales/en.json'
import ja from './locales/ja.json'

const browser = (typeof navigator !== 'undefined' && navigator.language) || 'en'
const initial = browser.startsWith('ja') ? 'ja' : 'en'

export const i18n = createI18n({
  legacy: false,
  globalInjection: true,
  locale: initial,
  fallbackLocale: 'en',
  messages: { en, ja },
})

export default i18n

