# 18 — Network status check + offline prompt

End-to-end offline awareness: the app no longer waits the full
10 s Dio `connectTimeout` to discover it has no network. Three
layers stack to provide both ambient status and per-request fail-
fast behaviour.

## What was added

* **`connectivity_plus: ^6.0.5`** in pubspec.yaml.

* **`NetworkStatusService`** (`lib/core/network/network_status.dart`)
  — long-lived broadcast service with three states (`unknown` /
  `online` / `offline`). Single subscription to
  `connectivity_plus.onConnectivityChanged` feeds every listener.
  Counts Wi-Fi / mobile / Ethernet / VPN as online; excludes
  `other` and `none`.

* **`NetworkInterceptor`** (`lib/core/api/interceptors/network_interceptor.dart`)
  — registered first in the Dio chain. Rejects offline requests
  immediately with `DioException(type: connectionError,
  error: ApiException(i18nKey: 'network.offline'))`. No 10 s
  spinner.

* **Polite-error wiring** in
  `lib/core/errors/polite_error.dart` — the `network.offline`
  key renders "You're offline. Connect to Wi-Fi or mobile data
  and try again."

* **`OfflineBanner`** (`lib/core/network/offline_banner.dart`) —
  slim red bar mounted once in `AppShell` above the active route.
  AnimatedSize + AnimatedSwitcher for smooth in/out. Read-only
  screens still work; the banner is an ambient cue, not a hard
  block.

## What it does *not* do

* Does not ping the backend itself — relies on OS reachability
  signal. Captive portals show "online" but their requests will
  surface a polite error via `ErrorInterceptor`.
* Does not queue offline mutations for later sync.
* Does not distinguish metered networks (could be a follow-up
  `data-saver` mode).

Commit: `5b6c5dd`.
