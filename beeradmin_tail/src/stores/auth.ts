// src/stores/auth.ts
import { defineStore } from 'pinia'
import { supabase } from '../lib/supabase'


type AuthState = {
  accessToken: string | null
  userId: string | null
  email: string | null
  username: string | null  // optional display name
}

export const useAuthStore = defineStore('auth', {
  state: (): AuthState => ({
    accessToken: null,
    userId: null,
    email: null,
    username: null,
  }),
  getters: {
    isAuthed: (s) => !!s.accessToken && !!s.userId,
  },
  actions: {
    async signIn(email: string, password: string) {
      const { data, error } = await supabase.auth.signInWithPassword({ email, password })
      if (error) throw error

      const { data1, error1 } = await supabase.functions.invoke("set-tenant", { body: {} });

      // Refresh session so JWT includes tenant_id
      await supabase.auth.refreshSession();

      console.log((await supabase.auth.getSession()).data.session?.user?.app_metadata);

      const session = data.session
      this.accessToken = session?.access_token ?? null
      this.userId = session?.user?.id ?? null
      this.email = session?.user?.email ?? null
      this.username = session?.user?.user_metadata?.username ?? null
      return data
    },

    async signOut() {
      const { error } = await supabase.auth.signOut()
      if (error) throw error
      this.$reset()
    },

    // Call at app start to sync with Supabase session
    async bootstrap() {
      const { data } = await supabase.auth.getSession()
      const session = data.session
      if (session) {
        this.accessToken = session.access_token
        this.userId = session.user.id
        this.email = session.user.email ?? null
        this.username = session.user.user_metadata?.username ?? null
      }

      // Keep Pinia in sync on auth events (token refresh, sign-in, sign-out)
      supabase.auth.onAuthStateChange((_event, sess) => {
        if (!sess) {
          this.$reset()
          return
        }
        this.accessToken = sess.access_token
        this.userId = sess.user.id
        this.email = sess.user.email ?? null
        this.username = sess.user.user_metadata?.username ?? null
      })
    },
  },
  persist: {
    key: 'auth',
    storage: window.localStorage,
  },
})
