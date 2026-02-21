// src/lib/supabase.ts
import { createClient, type SupabaseClient } from '@supabase/supabase-js'

const url = import.meta.env.VITE_SUPABASE_URL as string
const anon = import.meta.env.VITE_SUPABASE_ANON_KEY as string

// HMR-safe singleton (important in Vite/Nuxt dev mode)
const globalForSupabase = globalThis as unknown as {
  __supabase?: SupabaseClient<any, any, any>
}

export const supabase =
  globalForSupabase.__supabase ??
  createClient<any>(url, anon, {
  auth: {
    persistSession: false, // we'll persist via Pinia
    autoRefreshToken: true,
    detectSessionInUrl: true,
  },
})

if (!globalForSupabase.__supabase) {
  globalForSupabase.__supabase = supabase
}
