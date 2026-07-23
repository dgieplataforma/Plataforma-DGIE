'use strict';

const APP_URL = '/';
const APP_ICON = '/assets/dgie-app-icon-192.png';
const APP_BADGE = '/assets/dgie-app-icon-192.png';

self.addEventListener('install', () => self.skipWaiting());

self.addEventListener('activate', event => {
  event.waitUntil(self.clients.claim());
});

async function setBadge(count) {
  const value = Math.max(0, Number(count) || 0);
  try {
    if (value > 0 && 'setAppBadge' in self.navigator) {
      await self.navigator.setAppBadge(value);
    } else if (value === 0 && 'clearAppBadge' in self.navigator) {
      await self.navigator.clearAppBadge();
    }
  } catch (_) {}
}

self.addEventListener('push', event => {
  let payload = {};
  try {
    payload = event.data ? event.data.json() : {};
  } catch (_) {
    payload = { body: event.data ? event.data.text() : '' };
  }

  const title = String(payload.title || 'Nueva notificacion');
  const options = {
    body: String(payload.body || 'Tenes una novedad en la plataforma.'),
    icon: APP_ICON,
    badge: APP_BADGE,
    tag: String(payload.tag || `dgie-${Date.now()}`),
    renotify: true,
    requireInteraction: true,
    data: {
      url: String(payload.url || APP_URL),
      kind: String(payload.kind || ''),
      sourceId: String(payload.sourceId || '')
    }
  };

  event.waitUntil(Promise.all([
    self.registration.showNotification(title, options),
    setBadge(payload.unreadCount)
  ]));
});

self.addEventListener('notificationclick', event => {
  event.notification.close();
  const target = new URL(event.notification.data?.url || APP_URL, self.location.origin).href;
  event.waitUntil((async () => {
    const windows = await self.clients.matchAll({ type: 'window', includeUncontrolled: true });
    const current = windows.find(client => new URL(client.url).origin === self.location.origin);
    if (current) {
      if ('navigate' in current) await current.navigate(target);
      return current.focus();
    }
    return self.clients.openWindow(target);
  })());
});
