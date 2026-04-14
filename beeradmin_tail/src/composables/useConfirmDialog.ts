import { onBeforeUnmount, reactive } from 'vue'

export type ConfirmDialogTone = 'danger' | 'warning' | 'primary'

export type ConfirmDialogOptions = {
  title?: string
  message: string
  confirmLabel: string
  cancelLabel?: string
  tone?: ConfirmDialogTone
}

type ConfirmDialogState = {
  open: boolean
  title: string
  message: string
  confirmLabel: string
  cancelLabel: string
  tone: ConfirmDialogTone
}

export function useConfirmDialog() {
  const confirmDialog = reactive<ConfirmDialogState>({
    open: false,
    title: '',
    message: '',
    confirmLabel: '',
    cancelLabel: '',
    tone: 'primary',
  })

  let resolveConfirmation: ((confirmed: boolean) => void) | null = null

  function resetDialog() {
    confirmDialog.open = false
    confirmDialog.title = ''
    confirmDialog.message = ''
    confirmDialog.confirmLabel = ''
    confirmDialog.cancelLabel = ''
    confirmDialog.tone = 'primary'
  }

  function settleConfirmation(confirmed: boolean) {
    const resolve = resolveConfirmation
    resolveConfirmation = null
    resetDialog()
    resolve?.(confirmed)
  }

  function requestConfirmation(options: ConfirmDialogOptions) {
    if (resolveConfirmation) {
      settleConfirmation(false)
    }
    confirmDialog.open = true
    confirmDialog.title = options.title ?? ''
    confirmDialog.message = options.message
    confirmDialog.confirmLabel = options.confirmLabel
    confirmDialog.cancelLabel = options.cancelLabel ?? ''
    confirmDialog.tone = options.tone ?? 'primary'

    return new Promise<boolean>((resolve) => {
      resolveConfirmation = resolve
    })
  }

  function cancelConfirmation() {
    settleConfirmation(false)
  }

  function acceptConfirmation() {
    settleConfirmation(true)
  }

  onBeforeUnmount(() => {
    if (resolveConfirmation) settleConfirmation(false)
  })

  return {
    confirmDialog,
    requestConfirmation,
    cancelConfirmation,
    acceptConfirmation,
  }
}
