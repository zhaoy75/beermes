/* supabaseErrors.ts
 * A tiny mapper to present friendly error messages to end users.
 * Works with Supabase JS client (.from, .rpc, .auth, storage) and Postgres errors.
 */

export type FriendlyError = {
  code?: string;           // SQLSTATE or SDK code
  reason: "validation" | "auth" | "permission" | "not_found" | "conflict" | "network" | "rate_limit" | "server" | "unknown";
  message: string;         // user-facing (localized)
  devMessage?: string;     // raw technical message for logs
  hint?: string;           // optional UX hint
};

// Minimal shape of PostgREST/Supabase error objects we care about
export type SupabaseErrorLike = {
  code?: string;              // e.g. '23505', '42501'
  message?: string;           // e.g. 'duplicate key value violates unique constraint ...'
  details?: string;
  hint?: string;
  name?: string;              // e.g. 'AuthApiError', 'PostgrestError'
  status?: number;            // HTTP code (e.g. 401/403/404/409/429/5xx)
};

// Basic i18n dictionary (JP + EN). Replace with vue-i18n if you like.
const MESSAGES = {
  ja: {
    unknown: "エラーが発生しました。もう一度お試しください。",
    network: "ネットワークに接続できません。通信環境を確認してください。",
    auth_session: "セッションの有効期限が切れています。再ログインしてください。",
    auth_forbidden: "この操作を実行する権限がありません。",
    not_found: "対象データが見つかりません。",
    conflict: "同じ値が既に登録されています。",
    validation: "入力値が制約に違反しています。",
    rate_limit: "リクエストが多すぎます。しばらく待ってから再試行してください。",
    server: "サーバーで問題が発生しました。時間をおいて再度お試しください。",
    field_required: "必須項目が未入力です。",
    qty_positive: "数量は 0 より大きい必要があります。"
  },
  en: {
    unknown: "Something went wrong. Please try again.",
    network: "Network error. Please check your connection.",
    auth_session: "Your session has expired. Please sign in again.",
    auth_forbidden: "You do not have permission to perform this action.",
    not_found: "The requested data was not found.",
    conflict: "This value already exists.",
    validation: "Your input violates a constraint.",
    rate_limit: "Too many requests. Please try again later.",
    server: "Server error. Please try again later.",
    field_required: "This field is required.",
    qty_positive: "Quantity must be greater than zero."
  }
};

export type LocaleKey = keyof typeof MESSAGES;
let currentLocale: LocaleKey = "ja"; // default; set from your app at startup

export function setErrorLocale(locale: LocaleKey) {
  currentLocale = locale;
}

/** Optional constraint-name → friendlier message map */
const CONSTRAINT_MAP: Record<string, keyof typeof MESSAGES["ja"]> = {
  // example constraint names in your DDL:
  // 'uq_inv_mov_tenant_docno': 'conflict',
  // 'inv_mov_line_has_item': 'validation',
  // 'ck_materials_beer_abv': 'validation',
};

function t(key: keyof typeof MESSAGES["ja"]) {
  return MESSAGES[currentLocale][key];
}

/** Heuristics to categorize the error */
function categorize(e: SupabaseErrorLike): FriendlyError["reason"] {
  // Network layer (fetch failed) – SDK sets status undefined and message like 'Failed to fetch'
  if (!e || (e.status === undefined && e.code === undefined && e.message && /fetch|network/i.test(e.message))) {
    return "network";
  }
  if (e.status === 401) return "auth";
  if (e.status === 403) return "permission";
  if (e.status === 404) return "not_found";
  if (e.status === 409) return "conflict";
  if (e.status === 429) return "rate_limit";
  if (e.status && e.status >= 500) return "server";

  // SQLSTATE fallbacks
  switch (e.code) {
    case "23505": return "conflict";          // unique_violation
    case "23503": return "validation";        // foreign_key_violation
    case "23502": return "validation";        // not_null_violation
    case "23514": return "validation";        // check_violation
    case "42501": return "permission";        // insufficient_privilege (often RLS)
    default: return "unknown";
  }
}

/** Detect common auth/session issues from message text */
function isSessionExpired(e: SupabaseErrorLike): boolean {
  const msg = (e.message || "").toLowerCase();
  return (
    e.status === 401 ||
    /jwt|token|session.*(expired|invalid)/i.test(msg) ||
    /invalid authentication/i.test(msg)
  );
}

/** Map Supabase/Postgres error → user-friendly error */
export function mapSupabaseError(err: SupabaseErrorLike | null | undefined): FriendlyError | null {
  if (!err) return null;

  // If constraint name appears in message/details, apply custom mapping
  const blob = [err.message, err.details, err.hint].filter(Boolean).join(" ");
  for (const cname of Object.keys(CONSTRAINT_MAP)) {
    if (blob.includes(cname)) {
      const key = CONSTRAINT_MAP[cname];
      return {
        code: err.code,
        reason: "validation",
        message: t(key),
        devMessage: [err.message, err.details].filter(Boolean).join(" | "),
      };
    }
  }

  // Session-specific
  if (isSessionExpired(err)) {
    return {
      code: err.code || String(err.status || ""),
      reason: "auth",
      message: t("auth_session"),
      devMessage: [err.message, err.details].filter(Boolean).join(" | ")
    };
  }

  // RLS/permission hint from message
  if (/row-level security|rls|permission|not allowed/i.test(blob) || err.status === 403 || err.code === "42501") {
    return {
      code: err.code || String(err.status || ""),
      reason: "permission",
      message: t("auth_forbidden"),
      devMessage: [err.message, err.details].filter(Boolean).join(" | ")
    };
  }

  // SQLSTATE mapping
  const reason = categorize(err);
  const keyByReason: Record<FriendlyError["reason"], keyof typeof MESSAGES["ja"]> = {
    network: "network",
    auth: "auth_session",
    permission: "auth_forbidden",
    not_found: "not_found",
    conflict: "conflict",
    validation: "validation",
    rate_limit: "rate_limit",
    server: "server",
    unknown: "unknown",
  };

  return {
    code: err.code || String(err.status || ""),
    reason,
    message: t(keyByReason[reason]),
    devMessage: [err.message, err.details].filter(Boolean).join(" | "),
    hint: err.hint
  };
}

/** Convenience: wrap a Supabase call and return either data or throw FriendlyError */
export async function wrap<T>(p: Promise<{ data: T; error: SupabaseErrorLike | null }>): Promise<T> {
  const { data, error } = await p;
  if (error) {
    const friendly = mapSupabaseError(error);
    // Throwing the friendly error lets you catch & toast in one place
    throw friendly!;
  }
  return data;
}
