# Conversation - Fix scenario preview image CORP header and URL resolution

| Field | Value |
|---|---|
| Saved | 2026-06-01 13:43:49 |
| Commit | Fix scenario preview image CORP header and URL resolution |
| Project | C:\project\vLearn2 |

---

## User

hi

## Claude

Hi! How can I help you with vLearn2 today?

## User

backend api is nest js and adminpanel is next js

## Claude

Good to know. Let me update the memory with that detail.

**Tool - Read**

```
C:\Users\aaa\.claude\projects\c--project-vLearn2\memory\project_vlearn2.md
```

**Result**

```
<system-reminder>This memory is 16 days old. Memories are point-in-time observations, not live state — claims about code behavior or file:line citations may be outdated. Verify against current code before asserting as fact.</system-reminder>
1	---
2	name: project-vlearn2
3	description: vLearn2 FreeTalk English Learning App — Flutter (Android+Windows) + NestJS backend project context
4	metadata:
5	  type: project
6	---
7	
8	User is building "FreeTalk" — an English learning app with AI virtual tutor.
9	
10	**Stack:**
11	- Flutter (Android + Windows), Riverpod, go_router, Drift (SQLite), Rive animation
12	- NestJS backend, PostgreSQL, TypeORM, Claude API (claude-sonnet-4-6)
13	- i18n: English / Korean / Chinese
14	
15	**Key design files:** `vLearn2Spec/design_handoff_freetalk/` — tokens.json, strings.json, screens.md, components.md
16	
17	**Personas:** Maya, Leo, Sofia, Theo (4 AI tutor characters with Rive animation)
18	**Themes:** Apricot, Sage, Iris, Obsidian
19	
20	**Todo list:** saved to `todoList/` folder (10 files: 00_overview through 10_testing)
21	
22	**Why:** User generated design from claude.design and wants full implementation plan before coding starts.
23	
24	**How to app
...[truncated]
```

**Tool - Edit**

```
C:\Users\aaa\.claude\projects\c--project-vLearn2\memory\project_vlearn2.md
```

**Result**

```
The file C:\Users\aaa\.claude\projects\c--project-vLearn2\memory\project_vlearn2.md has been updated successfully. (file state is current in your context — no need to Read it back)
```

## Claude

Got it — NestJS backend API and Next.js admin panel. Memory updated. What are you working on?

## User

in scenario edit screen on admin panel on browser (http://localhost:4101/vAdmin/scenarios)
I can't see preview image. the error logs on chrome are like this.

api.ts:67 
 GET http://localhost:5101/api/admin/scenarios/2121c341-1f94-4c11-8396-ce26a5b147c8 401 (Unauthorized)
hot-reloader-client.js:187 [Fast Refresh] rebuilding
:5101/uploads/scenar…-ce26a5b147c8.png:1 
 GET http://localhost:5101/uploads/scenarios/2121c341-1f94-4c11-8396-ce26a5b147c8.png net::ERR_BLOCKED_BY_RESPONSE.NotSameOrigin 304 (Not Modified)
:5101/uploads/scenar…c8.background.png:1 
 GET http://localhost:5101/uploads/scenarios/2121c341-1f94-4c11-8396-ce26a5b147c8.background.png net::ERR_BLOCKED_BY_RESPONSE.NotSameOrigin 304 (Not Modified)
hot-reloader-client.js:44 [Fast Refresh] done in 704ms
2121c341-1f94-4c11-8…c8.background.png:1 
 GET http://localhost:4101/uploads/scenarios/2121c341-1f94-4c11-8396-ce26a5b147c8.background.png 404 (Not Found)
2121c341-1f94-4c11-8…-ce26a5b147c8.png:1 
 GET http://localhost:4101/uploads/scenarios/2121c341-1f94-4c11-8396-ce26a5b147c8.png 404 (Not Found)

## Claude

Two separate issues here: a 401 on the API call, and the image CORS block (`NotSameOrigin`) causing the browser to retry on the wrong port. Let me look at the relevant code.

**Tool - Agent**

```
{"description":"Explore admin panel image proxy/CORS setup","subagent_type":"Explore","prompt":"In the project at c:\\project\\vLearn2, look at:\n1. The Next.js admin panel (likely in admin/ or adminpanel/ subdirectory, running on port 4101) - find next.config.js/ts and any rewrites/proxy config for /uploads/\n2. The NestJS backend (running on port 5101) - find main.ts and any CORS config, plus how /uploads/ static files are served\n3. The scenario edit page in the admin panel - find how image URLs are constructed (looking for localhost:5101 or /uploads/ references)\n4. Any recent changes rela ...[truncated]
```

**Result**

```
Excellent! I have all the information I need. Let me provide a comprehensive report.

## Summary: Next.js Admin Panel & NestJS Backend - Uploads/CORS Configuration

### File Paths

**Next.js Admin Panel:**
- `c:\project\vLearn2\admin_panel\next.config.mjs` - Main Next.js configuration
- `c:\project\vLearn2\admin_panel\src\lib\api.ts` - API client wrapper
- `c:\project\vLearn2\admin_panel\src\lib\env.ts` - Environment validation
- `c:\project\vLearn2\admin_panel\src\app\(dashboard)\scenarios\[id]\page.tsx` - Scenario edit page (lines 60-82 for URL resolution)
- `c:\project\vLearn2\admin_panel\.env` - Environment config

**NestJS Backend:**
- `c:\project\vLearn2\backend\src\main.ts` - Bootstrap file (lines 86-97 for CORS & static files)
- `c:\project\vLearn2\backend\src\admin\admin-scenarios.controller.ts` - Upload handlers (lines 358-443)
- `c:\project\vLearn2\backend\src\database\entities\scenario.entity.ts` - Database schema for images
- `c:\project\vLearn2\backend\.env` - Backend environment config

---

### Current Configuration

**Next.js Admin Panel (port 4101):**
```javascript
// next.config.mjs
basePath: '/vAdmin',
trailingSlash: true,
async rewrites() {
  return [
    {
   
...[truncated]
```

## Claude

Clear picture now. There are two distinct issues:

1. **Preview section uses raw `scenario.image_url`** (relative path `/uploads/...`) instead of `resolveUploadUrl()` — browser loads from `localhost:4101` which 404s
2. **`ERR_BLOCKED_BY_RESPONSE.NotSameOrigin`** — this is a `Cross-Origin-Resource-Policy` (CORP) issue, not just CORS. Even with CORS headers, the browser blocks cross-origin image loads unless the response includes `Cross-Origin-Resource-Policy: cross-origin`

Let me fix both.

**Tool - Read**

```
c:\project\vLearn2\admin_panel\src\app\(dashboard)\scenarios\[id]\page.tsx
```

**Result**

```
300	        </CardContent>
301	      </Card>
302	
303	      <Card>
304	        <CardHeader>
305	          <CardTitle>Preview</CardTitle>
306	        </CardHeader>
307	        <CardContent>
308	          <div className="space-y-4">
309	            <div>
310	              <p className="text-sm font-medium">Current images</p>
311	              <div className="grid gap-3 md:grid-cols-1">
312	                {scenario.background_image_url && (
313	                  <div>
314	                    <p className="text-xs text-muted-foreground">Scene background</p>
315	                    <img
316	                      src={scenario.background_image_url}
317	                      alt="Background"
318	                      className="mt-2 h-40 w-full rounded-lg object-cover border border-border"
319	                    />
320	                  </div>
321	                )}
322	                {scenario.image_url && (
323	                  <div>
324	                    <p className="text-xs text-muted-foreground">Hero image</p>
325	                    <img
326	                      src={scenario.image_url}
327	                      alt="Hero"
328	                      className="mt-2 h-40 w-ful
...[truncated]
```

**Tool - Read**

```
c:\project\vLearn2\backend\src\main.ts
```

**Result**

```
1	// vLearn2 — backend bootstrap.
2	//
3	// Wires the NestJS app the way the rest of the codebase assumes:
4	//   * helmet for security headers and CORS pinned to CORS_ORIGINS;
5	//   * compression with a runtime kill-switch (admins can disable gzip
6	//     without restarting via the `system.gzip_enabled` app_config flag);
7	//   * a global validation pipe that strips unknown fields so DTOs are the
8	//     single source of truth for request payloads;
9	//   * an /api prefix on every route except /health and /uploads/* (static
10	//     file serving for scenario / persona / news images);
11	//   * Swagger docs at /api/docs with persisted bearer-token auth.
12	//
13	// All real business logic lives inside feature modules under src/*. This
14	// file is intentionally thin.
15	
16	import { NestFactory } from '@nestjs/core';
17	import { ValidationPipe, Logger } from '@nestjs/common';
18	import { DocumentBuilder, SwaggerModule } from '@nestjs/swagger';
19	import { ConfigService } from '@nestjs/config';
20	import { NestExpressApplication } from '@nestjs/platform-express';
21	import helmet from 'helmet';
22	import compression from 'compression';
23	import cors from 'cors';
24	import * as
...[truncated]
```

## Claude

Now I can see exactly what needs fixing. Let me also check where `resolveUploadUrl` is defined in the page component.

**Tool - Read**

```
c:\project\vLearn2\admin_panel\src\app\(dashboard)\scenarios\[id]\page.tsx
```

**Result**

```
50	
51	  const imagePreviewUrl = useMemo(
52	    () => (imageFile ? URL.createObjectURL(imageFile) : null),
53	    [imageFile],
54	  );
55	  const backgroundImagePreviewUrl = useMemo(
56	    () => (backgroundImageFile ? URL.createObjectURL(backgroundImageFile) : null),
57	    [backgroundImageFile],
58	  );
59	
60	  const uploadsOrigin = useMemo(() => {
61	    const base = env.NEXT_PUBLIC_API_BASE_URL;
62	    if (base.startsWith('http://') || base.startsWith('https://')) {
63	      try {
64	        const url = new URL(base);
65	        return `${url.origin}${url.pathname.replace(/\/api(?:\/backend)?$/, '')}`;
66	      } catch {
67	        return base.replace(/\/api(?:\/backend)?$/, '');
68	      }
69	    }
70	    if (typeof window !== 'undefined') {
71	      return `${window.location.origin}${base.replace(/\/api(?:\/backend)?$/, '')}`;
72	    }
73	    return '';
74	  }, []);
75	
76	  const resolveUploadUrl = (url: string | null) => {
77	    if (!url) return null;
78	    if (url.startsWith('/uploads')) {
79	      return `${uploadsOrigin}${url}`;
80	    }
81	    return url;
82	  };
83	
84	  useEffect(() => {
85	    return () => {
86	      if (imagePreviewUrl) URL.revokeObjectURL(image
...[truncated]
```

## Claude

Both fixes are clear. Making them now:

**Fix 1**: Preview section uses raw URLs — wrap with `resolveUploadUrl()`

**Fix 2**: Backend CORP header — add `Cross-Origin-Resource-Policy: cross-origin` to the uploads middleware

**Tool - Edit**

```
c:\project\vLearn2\admin_panel\src\app\(dashboard)\scenarios\[id]\page.tsx
```

**Result**

```
The file c:\project\vLearn2\admin_panel\src\app\(dashboard)\scenarios\[id]\page.tsx has been updated successfully. (file state is current in your context — no need to Read it back)
```

**Tool - Edit**

```
c:\project\vLearn2\backend\src\main.ts
```

**Result**

```
The file c:\project\vLearn2\backend\src\main.ts has been updated successfully. (file state is current in your context — no need to Read it back)
```

## Claude

Now commit and save the story.

**Tool - PowerShell**

```
Get-Date -Format 'yyMMdd_HHmmss'
```

**Result**

```
260601_134323
```

**Tool - Write**

```
c:\project\vLearn2\story_claude\2026_06_01\260601_134323_Fix_scenario_preview_image_CORP_and_URL_resolution.md
```

**Result**

```
File created successfully at: c:\project\vLearn2\story_claude\2026_06_01\260601_134323_Fix_scenario_preview_image_CORP_and_URL_resolution.md (file state is current in your context — no need to Read it back)
```

**Tool - Bash**

```
cd c:/project/vLearn2 && git add admin_panel/src/app/\(dashboard\)/scenarios/\[id\]/page.tsx backend/src/main.ts story_claude/2026_06_01/260601_134323_Fix_scenario_preview_image_CORP_and_URL_resolution.md && git commit -m "Fix scenario preview image CORP header and URL resolution"
```

---

## User prompts (verbatim)

### Prompt 1

```
hi
```

### Prompt 2

```
backend api is nest js and adminpanel is next js
```

### Prompt 3

```
in scenario edit screen on admin panel on browser (http://localhost:4101/vAdmin/scenarios)
I can't see preview image. the error logs on chrome are like this.

api.ts:67 
 GET http://localhost:5101/api/admin/scenarios/2121c341-1f94-4c11-8396-ce26a5b147c8 401 (Unauthorized)
hot-reloader-client.js:187 [Fast Refresh] rebuilding
:5101/uploads/scenar…-ce26a5b147c8.png:1 
 GET http://localhost:5101/uploads/scenarios/2121c341-1f94-4c11-8396-ce26a5b147c8.png net::ERR_BLOCKED_BY_RESPONSE.NotSameOrigin 304 (Not Modified)
:5101/uploads/scenar…c8.background.png:1 
 GET http://localhost:5101/uploads/scenarios/2121c341-1f94-4c11-8396-ce26a5b147c8.background.png net::ERR_BLOCKED_BY_RESPONSE.NotSameOrigin 304 (Not Modified)
hot-reloader-client.js:44 [Fast Refresh] done in 704ms
2121c341-1f94-4c11-8…c8.background.png:1 
 GET http://localhost:4101/uploads/scenarios/2121c341-1f94-4c11-8396-ce26a5b147c8.background.png 404 (Not Found)
2121c341-1f94-4c11-8…-ce26a5b147c8.png:1 
 GET http://localhost:4101/uploads/scenarios/2121c341-1f94-4c11-8396-ce26a5b147c8.png 404 (Not Found)
```

