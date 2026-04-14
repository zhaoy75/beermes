const DATE_INPUT_TYPES = new Set(['date', 'datetime-local'])

function isDateCapableInput(target: EventTarget | null): target is HTMLInputElement {
  return target instanceof HTMLInputElement && DATE_INPUT_TYPES.has(target.type)
}

export function tryOpenDateInputPicker(target: EventTarget | null) {
  if (!isDateCapableInput(target)) return
  if (target.disabled || target.readOnly) return
  if (typeof target.showPicker !== 'function') return

  try {
    target.showPicker()
  } catch {
    // Browsers may reject showPicker() when unsupported for the current interaction.
  }
}

export function bindGlobalDateInputPicker(root: Document = document) {
  const handleFocusIn = (event: FocusEvent) => {
    tryOpenDateInputPicker(event.target)
  }

  root.addEventListener('focusin', handleFocusIn)

  return () => {
    root.removeEventListener('focusin', handleFocusIn)
  }
}
