export function shouldRunDialogEnterAction(event: KeyboardEvent) {
  if (event.key !== 'Enter') return false
  if (event.defaultPrevented || event.isComposing) return false
  if (event.altKey || event.ctrlKey || event.metaKey || event.shiftKey) return false

  const target = event.target
  if (!(target instanceof HTMLElement)) return true
  if (target.isContentEditable) return false
  if (target.closest('[data-dialog-enter-ignore="true"]')) return false

  const tagName = target.tagName.toLowerCase()
  if (tagName === 'button' || tagName === 'a' || tagName === 'select' || tagName === 'textarea') return false

  if (target instanceof HTMLInputElement) {
    const type = target.type.toLowerCase()
    return !['button', 'checkbox', 'color', 'file', 'radio', 'range', 'reset', 'submit'].includes(type)
  }

  return true
}

export function runDialogEnterAction(event: KeyboardEvent, action: () => void) {
  if (!shouldRunDialogEnterAction(event)) return
  event.preventDefault()
  action()
}
