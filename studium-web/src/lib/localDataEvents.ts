export function notifyLocalDataChanged() {
  window.dispatchEvent(new Event('studium-local-data-change'))
}

export function notifySyncApplied() {
  window.dispatchEvent(new Event('studium-sync-applied'))
}

export function notifyLocalDataFromSync() {
  window.dispatchEvent(new CustomEvent('studium-local-data-change', { detail: { fromSync: true } }))
}
