# I'm going to use backend api in the unity3d project. this project is seperate pa

Session: `859710bb-e71a-42d3-b4d0-af5e037a10f3`
Saved: 2026-05-20T11:54:24.053Z

## User

I'm going to use backend api in the unity3d project. this project is seperate part for this project until now.
But now i have to integrate api to unity3d project. 
tell me how to do?

## Assistant

Here's a concrete plan. The backend is already REST/JSON over Bearer JWT, so integration is straightforward — the main work is on the Unity side.

## Approach

### 1. Pick a JSON library — **Newtonsoft.Json**

Don't use Unity's built-in `JsonUtility` — it doesn't handle `Dictionary<>`, polymorphism, or the snake_case fields the backend returns (e.g. `display_name`, `image_url`). Install:

```
Window → Package Manager → "+" → Add package by name → com.unity.nuget.newtonsoft-json
```

System.Text.Json works too but has IL2CPP/AOT pitfalls — Newtonsoft.Json Unity build is the path of least resistance.

### 2. Use **UnityWebRequest** (not HttpClient)

`UnityWebRequest` is the Unity-native HTTP client and works on every build target including WebGL (where `HttpClient`/`System.Net.Http` is restricted). Wrap it in a small `ApiClient` class.

### 3. Auth flow

Backend uses two parallel auth flows:

- **User-side** (mobile/app users): `POST /api/auth/signin` — see [backend/src/auth/](backend/src/auth/). Likely Google-ID-token-based (Flutter app uses it). Returns `{ accessToken, refreshToken, expiresIn }`. Token's `actor: 'user'`.
- **Admin-side**: `POST /api/admin/auth/signin` — email/password. Returns same shape. Token's `actor: 'admin'`.

For a Unity game client, you almost certainly want the **user-side** flow. Token lifetimes: 15min access, 7d refresh (per [backend/.env:22-23](backend/.env#L22-L23)). Refresh by `POST /api/auth/refresh`.

### 4. Code skeleton

```csharp
using System;
using System.Collections;
using System.Text;
using UnityEngine;
using UnityEngine.Networking;
using Newtonsoft.Json;

public class ApiClient : MonoBehaviour {
    public string BaseUrl = "http://192.168.135.30:5101/api";   // ← LAN IP, not localhost
    public string AccessToken { get; private set; }
    public string RefreshToken { get; private set; }

    public IEnumerator Post<TReq, TRes>(string path, TReq body, Action<TRes> ok, Action<long, string> err) {
        var req = new UnityWebRequest($"{BaseUrl}{path}", "POST");
        req.uploadHandler = new UploadHandlerRaw(Encoding.UTF8.GetBytes(JsonConvert.SerializeObject(body)));
        req.downloadHandler = new DownloadHandlerBuffer();
        req.SetRequestHeader("Content-Type", "application/json");
        if (!string.IsNullOrEmpty(AccessToken))
            req.SetRequestHeader("Authorization", $"Bearer {AccessToken}");

        yield return req.SendWebRequest();

        if (req.responseCode == 401 && !string.IsNullOrEmpty(RefreshToken)) {
            yield return RefreshTokens();
            // retry once with new token... (omitted for brevity)
        }

        if (req.result == UnityWebRequest.Result.Success)
            ok(JsonConvert.DeserializeObject<TRes>(req.downloadHandler.text));
        else
            err(req.responseCode, req.downloadHandler.text ?? req.error);
    }

    IEnumerator RefreshTokens() {
        // POST /api/auth/refresh { refreshToken } → { accessToken, refreshToken }
        yield break;
    }
}
```

Same shape for `Get`, `Patch`, `Delete`. If you have UniTask installed, replace coroutines with `async UniTask<T>` — much cleaner.

### 5. DTOs

Mirror the backend's response shapes. Because backend uses snake_case for entity fields:

```csharp
public class UserMe {
    [JsonProperty("user_id")] public string UserId;
    [JsonProperty("display_name")] public string DisplayName;
    [JsonProperty("xp_total")] public int XpTotal;
    [JsonProperty("current_level")] public int CurrentLevel;
}
```

### 6. Token storage

In memory only is fine for single-session play. For "remember me" across launches, save the **refresh token** (not the access) to encrypted storage:

- **PlayerPrefs** — easy, *not* encrypted, fine for dev only.
- **Production** — wrap with a platform keystore: `EasySave3`, `Unity.Cryptography`, or a small Android Keystore / iOS Keychain plugin.

## Gotchas before you ship

1. **HTTPS in production.** Locally `http://192.168.135.30:5101` works. On Android API ≥ 28, cleartext is blocked by default — your release build needs either HTTPS (the right answer) or `android:usesCleartextTraffic="true"` in `AndroidManifest.xml` (dev shortcut only). iOS ATS likewise wants HTTPS. Put a TLS-terminating reverse proxy (nginx/Caddy) in front of the backend before going to prod.

2. **WebGL builds enforce CORS.** If you ship a Unity WebGL build, the browser will check the backend's `Access-Control-Allow-Origin`. Add the WebGL host to [backend/.env#L9](backend/.env#L9) `CORS_ORIGINS`. Standalone/iOS/Android builds don't hit this check.

3. **Tokens are JWTs with `actor` claim.** The Bearer token's payload includes `{ sub, role, permissions, actor: 'user'|'admin' }`. The backend guards on `actor` for admin routes; you can't use an admin token from Unity to hit user routes and vice versa.

4. **Backend defaults to `localhost:3000` if `NEXT_PUBLIC_API_BASE_URL` isn't set** — you're not Next.js, so that doesn't affect Unity, but make sure your `BaseUrl` matches the box the backend is actually running on (it's `5101` on this machine, not `3000`).

5. **CSRF, refresh-token rotation.** The backend doesn't use cookies, so CSRF isn't a concern — Bearer tokens in headers are fine. Refresh-token rotation IS enforced: each `/auth/refresh` invalidates the old refresh token, so race conditions where two clients refresh at the same time can fail one of them. Don't run refresh in parallel.

## What I'd suggest doing now

1. **Decide build targets** (Standalone? Mobile? WebGL?) — that gates the HTTPS/CORS work above.
2. **Confirm which auth flow** your Unity client uses — likely user-side `/api/auth/signin`, but you may need a new endpoint if the Flutter app's Google-ID-token flow doesn't fit Unity (Unity's Google Sign-In plugins differ from Flutter's).
3. **I can scaffold a working `ApiClient.cs` + DTOs** for whichever endpoints you want to call first (probably signin + a couple of read endpoints to prove the loop). Just point me at the Unity project's path and tell me which endpoints to wire up first.

Which build targets do you care about, and do you want me to write the scaffolding now?
