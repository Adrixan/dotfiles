---
name: pwa-offline-architect
description: >-
  Architect and implement offline-first Progressive Web Apps (PWAs), Service Workers,
  CacheStorage, IndexedDB data persistence (Dexie.js, idb, idb-keyval), background sync,
  and offline asset caching. Use when developing or debugging offline PWA applications,
  caching strategies, or client-side databases.
---

# PWA & Offline-First Architecture Skill

This skill provides step-by-step procedures for building and debugging robust, offline-first PWAs and client-side storage systems in React, Vite, and vanilla web projects.

## 1. Core Principles

- **Cache-First for Static Assets**: Cache application shell (HTML, CSS, JS bundles, web fonts, audio/image assets).
- **IndexedDB for Dynamic & User Data**: Use high-level wrappers like `dexie`, `idb`, or `idb-keyval` for structured user progress, scan results, or trainer state.
- **Graceful Fallbacks**: Ensure apps remain fully functional when `navigator.onLine === false`.
- **Atomic Migrations**: Always version IndexedDB schemas to prevent data corruption during client updates.

## 2. Recommended Stack & Patterns

### A. IndexedDB with Dexie / idb
- Store structured relational entities (e.g. scans, scores, student profiles, audio blobs).
- Always wrap database transactions in try/catch and handle quota exceeded exceptions (`QuotaExceededError`).
- In React, utilize hooks (`useLiveQuery` from `dexie-react-hooks` or Zustand synced with IndexedDB).

### B. Service Worker Caching Strategies
1. **Network First with Cache Fallback**: For API requests that should be fresh if online (e.g., student sync).
2. **Stale While Revalidate**: For semi-static resources (e.g., curriculum configurations).
3. **Cache First (Cache Falling Back to Network)**: For immutable versioned bundles, audio files, icons, and fonts.

### C. Web Manifest Checklist
- `id`, `name`, `short_name`, `start_url: "/"`, `display: "standalone"`.
- `background_color`, `theme_color`.
- Icon definitions for 192x192, 512x512, and maskable icons.

## 3. Verification & Testing Steps
1. Run static validation on service worker registration and manifest.
2. Simulate offline mode via browser devtools / Playwright (`context.setOffline(true)`).
3. Verify that all essential routes, assets, and data queries function without network calls.
