# can you print log to console when user signin? I want know if the app send to co

Session: `c8b9bc59-8e0b-457d-a3e0-6557fcbf5b50`
Saved: 2026-05-26T01:13:46.494Z

## User

can you print log to console when user signin?
I want know if the app send to correct host address

## Assistant

You already have logs but they're scattered — `RequestLogInterceptor` prints every request URL, and `apiClientProvider` prints `config_baseurl111/222` once at startup. The cleanest fix is to add one explicit `[signin]` line right at the call site so the host shows next to the username, easy to grep.

## Assistant

Done. Now when the user taps **Sign in**, Logcat / dev console will show:

```
[auth.signin] target=http://172.86.121.43:80/vfls/auth/signin user=alex_kr
→ POST http://172.86.121.43:80/vfls/auth/signin
   Authorization: (none)
   body: {cidUsername: alex_kr, password: ...}
← 200 POST http://172.86.121.43:80/vfls/auth/signin
```

To filter in Android Studio Logcat: set **Tag: `flutter`** and **search: `auth.`** — that catches both `auth.signin` and `auth.signup` and ignores everything else. Password is not logged in the new line (it still appears in `RequestLogInterceptor`'s body dump, which is debug-only).
