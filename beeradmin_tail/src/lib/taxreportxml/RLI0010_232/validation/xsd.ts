import type {
  RLI0010_232_ValidationMessage,
  RLI0010_232_XsdValidateRequest,
  RLI0010_232_XsdValidateResponse,
} from '../types'

const XSD_VALIDATION_ENABLED = parseEnabledFlag(import.meta.env.VITE_TAX_REPORT_XML_VALIDATION_ENABLED)
const EXTERNAL_VALIDATOR_URL = String(import.meta.env.VITE_TAX_REPORT_XML_VALIDATOR_URL || '').trim()

export class XsdValidationError extends Error {
  status: number | null
  messages: RLI0010_232_ValidationMessage[]

  constructor(message: string, options: { status?: number | null; messages?: RLI0010_232_ValidationMessage[] } = {}) {
    super(message)
    this.name = 'XsdValidationError'
    this.status = options.status ?? null
    this.messages = options.messages ?? []
  }
}

export async function validateXsdRequest(request: RLI0010_232_XsdValidateRequest) {
  if (!XSD_VALIDATION_ENABLED) {
    return {
      reportName: request.reportName,
      valid: true,
      messages: [{
        level: 'warning',
        source: 'xsd',
        code: 'XSD_VALIDATION_DISABLED',
        message: 'XSD validation is disabled by VITE_TAX_REPORT_XML_VALIDATION_ENABLED.',
      }],
    } as RLI0010_232_XsdValidateResponse
  }

  if (EXTERNAL_VALIDATOR_URL) {
    try {
      const response = await fetch(EXTERNAL_VALIDATOR_URL, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
        },
        body: JSON.stringify(request),
      })

      const payload = await readResponsePayload(response)
      if (!response.ok) {
        throw new XsdValidationError(
          payload.message ?? 'XSD validation failed.',
          {
            status: response.status,
            messages: payload.messages,
          },
        )
      }

      return {
        reportName: request.reportName,
        valid: true,
        messages: payload.messages,
      } as RLI0010_232_XsdValidateResponse
    } catch (error) {
      if (error instanceof XsdValidationError) throw error
      throw new XsdValidationError(
        `Cannot reach the XSD validator service at ${EXTERNAL_VALIDATOR_URL}. Start the validator before saving or generating XML.`,
        {
          status: null,
          messages: [{
            level: 'error',
            source: 'xsd',
            code: 'XSD_VALIDATOR_UNAVAILABLE',
            message: `Cannot reach the XSD validator service at ${EXTERNAL_VALIDATOR_URL}.`,
          }],
        },
      )
    }
  }

  throw new XsdValidationError(
    'No XSD validator URL is configured. Set VITE_TAX_REPORT_XML_VALIDATOR_URL.',
    {
      status: null,
      messages: [{
        level: 'error',
        source: 'xsd',
        code: 'XSD_VALIDATOR_NOT_CONFIGURED',
        message: `No XSD validator URL is configured. Set VITE_TAX_REPORT_XML_VALIDATOR_URL.`,
      }],
    },
  )
}

export async function parseXsdValidationError(error: unknown) {
  if (error instanceof XsdValidationError) return error
  const record = error as { message?: unknown; context?: unknown; status?: unknown }
  const responsePayload = await readResponsePayload(record.context)
  const status = typeof (record as { status?: unknown }).status === 'number'
    ? (record as { status?: number }).status ?? null
    : responsePayload.status
  const messages = responsePayload.messages.length > 0
    ? responsePayload.messages
    : extractMessages(record.context)
  const rawMessage = typeof record.message === 'string' ? record.message : null
  const message = isTransportFailure(rawMessage, status)
    ? buildTransportFailureMessage()
    : responsePayload.message
      ? responsePayload.message
      : typeof record.message === 'string'
      ? record.message
      : messages[0]?.message ?? 'XSD validation failed.'
  return new XsdValidationError(message, {
    status,
    messages: messages.length > 0
      ? messages
      : isTransportFailure(rawMessage, status)
        ? [{
            level: 'error',
            source: 'xsd',
            code: 'XSD_VALIDATION_FUNCTION_UNAVAILABLE',
            message,
          }]
        : [],
  })
}

function isTransportFailure(message: string | null, status: number | null) {
  if (status !== null) return false
  if (!message) return false
  return /Failed to send a request/i.test(message) || /fetch/i.test(message)
}

async function readResponsePayload(value: unknown) {
  if (!(value instanceof Response)) {
    return {
      status: null as number | null,
      message: null as string | null,
      messages: [] as RLI0010_232_ValidationMessage[],
    }
  }

  try {
    const payload = await value.clone().json() as {
      message?: unknown
      error?: unknown
      messages?: unknown
    }
    const messages = Array.isArray(payload.messages)
      ? payload.messages.filter(isValidationMessage)
      : []
    const message = typeof payload.message === 'string'
      ? payload.message
      : typeof payload.error === 'string'
        ? payload.error
        : messages[0]?.message ?? null
    return {
      status: value.status,
      message,
      messages,
    }
  } catch {
    try {
      const text = await value.clone().text()
      return {
        status: value.status,
        message: text || null,
        messages: [] as RLI0010_232_ValidationMessage[],
      }
    } catch {
      return {
        status: value.status,
        message: null,
        messages: [] as RLI0010_232_ValidationMessage[],
      }
    }
  }
}

function extractMessages(value: unknown) {
  if (!value || typeof value !== 'object') return []
  const record = value as { messages?: unknown }
  if (!Array.isArray(record.messages)) return []
  return record.messages.filter(isValidationMessage)
}

function isValidationMessage(value: unknown): value is RLI0010_232_ValidationMessage {
  if (!value || typeof value !== 'object') return false
  const record = value as Record<string, unknown>
  return typeof record.level === 'string' &&
    typeof record.source === 'string' &&
    typeof record.code === 'string' &&
    typeof record.message === 'string'
}

function parseEnabledFlag(value: unknown) {
  const normalized = String(value ?? '').trim().toLowerCase()
  if (!normalized) return true
  return !['0', 'false', 'off', 'no'].includes(normalized)
}

function buildTransportFailureMessage() {
  if (EXTERNAL_VALIDATOR_URL) {
    return `Cannot reach the XSD validator service at ${EXTERNAL_VALIDATOR_URL}. Start the validator before saving or generating XML.`
  }
  return 'Cannot reach the XSD validator service. Set VITE_TAX_REPORT_XML_VALIDATOR_URL before saving or generating XML.'
}
