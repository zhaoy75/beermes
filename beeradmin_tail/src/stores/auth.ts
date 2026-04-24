// src/stores/auth.ts
import { defineStore } from 'pinia'
import { supabase } from '../lib/supabase'
import { useRuleengineLabelsStore } from './ruleengineLabels'

let authListenerSet = false

type AuthState = {
  accessToken: string | null
  userId: string | null
  email: string | null
  username: string | null  // optional display name
  tenantId: string | null
  systemRole: string | null
  isSystemAdmin: boolean
}

function applySession(target: AuthState, session: {
  access_token: string
  user: {
    id: string
    email?: string | null
    user_metadata?: Record<string, unknown>
    app_metadata?: Record<string, unknown>
  }
} | null) {
  target.accessToken = session?.access_token ?? null
  target.userId = session?.user?.id ?? null
  target.email = session?.user?.email ?? null
  target.username = typeof session?.user?.user_metadata?.username === 'string'
    ? session.user.user_metadata.username
    : null
  target.tenantId = typeof session?.user?.app_metadata?.tenant_id === 'string'
    ? session.user.app_metadata.tenant_id
    : null
  target.systemRole = typeof session?.user?.app_metadata?.system_role === 'string'
    ? session.user.app_metadata.system_role
    : null
  target.isSystemAdmin = Boolean(
    session?.user?.app_metadata?.is_system_admin ||
    session?.user?.app_metadata?.system_role,
  )
}

export const useAuthStore = defineStore('auth', {
  state: (): AuthState => ({
    accessToken: null,
    userId: null,
    email: null,
    username: null,
    tenantId: null,
    systemRole: null,
    isSystemAdmin: false,
  }),
  getters: {
    isAuthed: (s) => !!s.accessToken && !!s.userId,
  },
  actions: {
    async loadRuleengineLabelsIfAuthed(force = false) {
      if (!this.accessToken || !this.userId) return
      try {
        await useRuleengineLabelsStore().loadLabels({ tenantId: this.tenantId, force })
      } catch (err) {
        console.warn('ruleengine label cache load failed', err)
      }
    },

    async signIn(email: string, password: string) {
      const { data, error } = await supabase.auth.signInWithPassword({ email, password })
      if (error) throw error

      const { error: tenantError } = await supabase.functions.invoke('set-tenant', { body: {} })
      if (tenantError) {
        // Allow users with preassigned system scope to continue even if no tenant is resolved here.
        console.warn('set-tenant failed during sign-in', tenantError)
      }

      const refreshed = await supabase.auth.refreshSession()
      const session = refreshed.data.session ?? data.session
      applySession(this, session)
      await this.loadRuleengineLabelsIfAuthed(true)
      return data
    },

    async signOut() {
      const { error } = await supabase.auth.signOut()
      if (error) throw error
      useRuleengineLabelsStore().clearLabels()
      this.$reset()
    },

    // Call at app start to sync with Supabase session
    async bootstrap() {
      const { data } = await supabase.auth.getSession()
      applySession(this, data.session)
      await this.loadRuleengineLabelsIfAuthed(true)

      // Keep Pinia in sync on auth events (token refresh, sign-in, sign-out)
      if (authListenerSet) return
      authListenerSet = true
      supabase.auth.onAuthStateChange((_event, sess) => {
        if (!sess) {
          useRuleengineLabelsStore().clearLabels()
          this.$reset()
          const path = window.location.pathname
          if (path !== '/signin' && path !== '/signup' && path !== '/accept-invite') {
            const redirect = encodeURIComponent(window.location.pathname + window.location.search + window.location.hash)
            window.location.assign(`/signin?redirect=${redirect}`)
          }
          return
        }
        applySession(this, sess)
        void this.loadRuleengineLabelsIfAuthed()
      })
    },
  },
  persist: {
    key: 'auth',
    storage: window.localStorage,
  },
})
