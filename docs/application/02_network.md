# Application — Network status

Recently added in task 18. Two layers:

## 1. Transport-level reachability — `NetworkStatusService`

File: `lib/core/network/network_status.dart`

Wraps `connectivity_plus` and exposes a three-way state:

| State     | Meaning                                                |
| --------- | ------------------------------------------------------ |
| `unknown` | We haven't sampled yet — UI hides the banner          |
| `online`  | At least one of Wi-Fi / mobile / Ethernet / VPN is up |
| `offline` | None of the above                                      |

A single subscription on `connectivity_plus.onConnectivityChanged`
feeds every listener through a broadcast stream. The provider lives
for the whole app session (`networkStatusServiceProvider`); UI code
reads `networkStatusProvider` (a `StreamProvider<NetworkStatus>`
that emits the current cached value synchronously first).

`connectivity_plus` reports *transport* presence, not actual internet.
A captive portal will still register as "online". The next layer
catches that.

## 2. Request-level short-circuit — `NetworkInterceptor`

File: `lib/core/api/interceptors/network_interceptor.dart`

Sits **first** in the Dio interceptor chain. On every outbound
request:

1. If `NetworkStatusService.status == NetworkStatus.offline`, reject
   the request immediately with a `DioException(type:
   connectionError, error: ApiException(i18nKey: 'network.offline'))`.
2. Otherwise, hand off to the next interceptor.

Why this matters: without the interceptor, an offline request waits
the full `connectTimeout` (10 s) before failing. The user sees a long
spinner before the polite "no connection" message.

`politeMessageFor` recognises `network.offline` and renders
> "You're offline. Connect to Wi-Fi or mobile data and try again."

## 3. Ambient banner — `OfflineBanner`

File: `lib/core/network/offline_banner.dart`

Slim red bar wedged above the active route inside `AppShell`. Slides
in on offline, slides out on online. Does **not** block input —
read-only screens still work from local cache (drift DB), and the
banner is just an ambient cue.

## Where it gets wired in

| Surface             | Wired by                                  |
| ------------------- | ----------------------------------------- |
| Dio short-circuit   | `apiClientProvider` (interceptor order)   |
| Global banner       | `AppShell.build` wraps body in Column     |
| Per-screen handler  | catch `DioException` → `politeMessageFor` |

## What it does *not* do

* It does **not** ping the backend; it trusts the OS reachability
  signal. Captive portals or unreachable backends pass through.
* It does **not** queue / retry mutations offline. Sync-when-online
  is out of scope; offline mutations are rejected.
* It does **not** distinguish slow / metered networks. A future
  `data-saver` mode could live alongside this service.
