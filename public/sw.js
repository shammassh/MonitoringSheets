// Service Worker for FS Monitoring PWA
// Enables offline functionality

const CACHE_NAME = 'fs-monitoring-v1';
const OFFLINE_URL = '/offline.html';

// Files to cache for offline use
const STATIC_ASSETS = [
    '/',
    '/offline.html',
    '/css/app.css',
    '/css/responsive.css',
    '/js/app.js',
    '/js/offline-db.js',
    '/js/sync-service.js',
    '/manifest.json',
    '/icons/icon-192.png',
    '/icons/icon-512.png'
];

// API routes to cache responses
const API_CACHE = 'fs-monitoring-api-v1';
const CACHEABLE_API_ROUTES = [
    '/api/auditor/stores',
    '/api/auditor/checklists'
];

// Install event - cache static assets
self.addEventListener('install', (event) => {
    console.log('[SW] Installing Service Worker...');
    event.waitUntil(
        caches.open(CACHE_NAME)
            .then((cache) => {
                console.log('[SW] Caching static assets');
                return cache.addAll(STATIC_ASSETS);
            })
            .then(() => self.skipWaiting())
    );
});

// Activate event - clean old caches
self.addEventListener('activate', (event) => {
    console.log('[SW] Activating Service Worker...');
    event.waitUntil(
        caches.keys().then((cacheNames) => {
            return Promise.all(
                cacheNames
                    .filter((name) => name !== CACHE_NAME && name !== API_CACHE)
                    .map((name) => caches.delete(name))
            );
        }).then(() => self.clients.claim())
    );
});

// Fetch event - serve from cache or network
self.addEventListener('fetch', (event) => {
    const { request } = event;
    const url = new URL(request.url);

    // Skip non-GET requests
    if (request.method !== 'GET') {
        return;
    }

    // Handle API requests
    if (url.pathname.startsWith('/api/')) {
        event.respondWith(handleApiRequest(request));
        return;
    }

    // Handle static assets
    event.respondWith(handleStaticRequest(request));
});

// Handle API requests - Network first, fallback to cache
async function handleApiRequest(request) {
    const url = new URL(request.url);
    
    try {
        const response = await fetch(request);
        
        // Cache successful responses for cacheable routes
        if (response.ok && CACHEABLE_API_ROUTES.some(route => url.pathname.includes(route))) {
            const cache = await caches.open(API_CACHE);
            cache.put(request, response.clone());
        }
        
        return response;
    } catch (error) {
        // Network failed, try cache
        const cachedResponse = await caches.match(request);
        if (cachedResponse) {
            console.log('[SW] Serving API from cache:', url.pathname);
            return cachedResponse;
        }
        
        // Return offline JSON response
        return new Response(
            JSON.stringify({ offline: true, message: 'You are offline' }),
            { headers: { 'Content-Type': 'application/json' } }
        );
    }
}

// Handle static requests - Cache first, fallback to network
async function handleStaticRequest(request) {
    const cachedResponse = await caches.match(request);
    
    if (cachedResponse) {
        return cachedResponse;
    }

    try {
        const response = await fetch(request);
        
        // Cache successful responses
        if (response.ok) {
            const cache = await caches.open(CACHE_NAME);
            cache.put(request, response.clone());
        }
        
        return response;
    } catch (error) {
        // Return offline page for navigation requests
        if (request.mode === 'navigate') {
            return caches.match(OFFLINE_URL);
        }
        
        throw error;
    }
}

// Background Sync - sync pending data when online
self.addEventListener('sync', (event) => {
    console.log('[SW] Background sync triggered:', event.tag);
    
    if (event.tag === 'sync-pending-audits') {
        event.waitUntil(syncPendingAudits());
    }
});

// Sync pending audits to server
async function syncPendingAudits() {
    console.log('[SW] Syncing pending audits...');
    
    // Notify all clients to sync
    const clients = await self.clients.matchAll();
    clients.forEach(client => {
        client.postMessage({
            type: 'SYNC_PENDING',
            message: 'Syncing offline data...'
        });
    });
}

// Listen for messages from main app
self.addEventListener('message', (event) => {
    if (event.data.type === 'SKIP_WAITING') {
        self.skipWaiting();
    }
});

console.log('[SW] Service Worker loaded');
