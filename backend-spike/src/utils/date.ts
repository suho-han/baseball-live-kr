export function normalizeInputDate(input?: string): string {
  if (!input) {
    return new Date().toISOString().slice(0, 10)
  }

  const digits = input.replace(/[^0-9]/g, '')
  if (digits.length !== 8) {
    throw new Error(`invalid date format: ${input}`)
  }

  return `${digits.slice(0, 4)}-${digits.slice(4, 6)}-${digits.slice(6, 8)}`
}

export function toKboDate(input?: string): string {
  return normalizeInputDate(input).replaceAll('-', '')
}
