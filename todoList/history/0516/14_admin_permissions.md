# 14 – Admin Permissions (RBAC)

Granular permission system for the admin panel. Replaces the coarse "admin vs superadmin" check from §12 / §13 with **named, individually-grantable permissions**. The superadmin (one per system, bootstrapped on first sign-up) manages sub-admin permissions.

This file is the **single source of truth** for:
- Who can do what in the admin panel
- How permissions are granted, revoked, and audited
- The bootstrap / sign-up flow
- Per-endpoint permission requirements (mapping table in §14.8)

---

## 14.1 Goals & Non-Goals

### Goals
- Two admin tiers: **superadmin** (1) and **sub-admin** (N)
- Superadmin can grant **fine-grained permissions** to sub-admins (e.g. "can edit scenarios but not view transcripts")
- Permissions are **named** and **discoverable** — the future Next.js admin panel reads a catalog endpoint and renders checkboxes
- **Safe bootstrap** — the first admin sign-up creates the superadmin, then admin sign-up auto-closes
- **Per-action audit trail** — every permission grant / revoke / role change records who did it and when
- A sub-admin trying to use an endpoint they lack the permission for gets **403 + the permission key they're missing** (so the admin panel can guide them)

### Non-Goals (v1)
- **Multiple superadmins**. Exactly one at a time. Handover is an explicit, audited two-step. Multiple superadmins muddle audit attribution and create coordination overhead.
- **Custom permission strings** at runtime. The catalog is **code-defined**; adding a permission means a code change + redeploy (deliberate — prevents typosquatting permissions and keeps the catalog tight).
- **Permission groups / roles**. Just flat permissions for v1. The admin panel can show UI presets (e.g. "Content Manager bundle") that grant multiple permissions in one click, but backend stores individual permissions.
- **Hierarchical permissions / inheritance**. No "manage" implies "view". Each permission is independent; the panel UI hints at dependencies.
- **Time-bound permissions** (e.g. "expires in 7 days"). Out of scope; revoke manually.

---

## 14.2 Admin Type Hierarchy

| Tier | DB `role` value | How created | Count limit | Effective permissions |
|------|----------------|-------------|-------------|----------------------|
| User | `'user'` | Public sign-up at `/auth/signup` | Unlimited | None (no admin panel access) |
| Sub-admin | `'admin'` | Created by superadmin via `POST /admin/admins` | Unlimited | Only what's in `admin_permissions` table for this user |
| Superadmin | `'superadmin'` | First admin sign-up at `/admin/auth/signup` (bootstrap), OR transfer from existing superadmin | **Exactly 1** | All permissions implicitly; cannot be checked against catalog (always returns true) |

**Critical invariant**: at any point in time, exactly one user has `role='superadmin'` once the system is bootstrapped. Migration / signup logic enforces this with a partial unique index:

```sql
CREATE UNIQUE INDEX uniq_one_superadmin ON users (role) WHERE role = 'superadmin';
```

---

## 14.3 Bootstrap & Sign-up Flow

### 14.3.1 First Admin (Superadmin Bootstrap)

```
POST /admin/auth/signup
{
  "email": "founder@example.com",
  "password": "...",
  "displayName": "Founder"
}
```

**Logic:**
1. Count rows where `role IN ('admin', 'superadmin')` AND `status != 'deleted'`
2. If count = 0 → create user with `role='superadmin'`, return JWT pair
3. If count ≥ 1 → return **403** with `{i18nKey: 'admin.signup_closed', message: 'Admin sign-up is closed; ask your superadmin to invite you.'}`

This endpoint is **public** but auto-closes after the first successful signup. No special env flag needed; the closure is data-driven.

- [ ] **14.3.1.1** Endpoint validates email uniqueness, password strength (min 12 chars for admins — stricter than user signups)
- [ ] **14.3.1.2** Returns 403 immediately when admin count ≥ 1 (no auth attempt logged to avoid timing leaks)
- [ ] **14.3.1.3** Successful bootstrap fires an audit-log entry with `action='admin.bootstrap'`
- [ ] **14.3.1.4** A loud one-time warning is logged at server boot if `role='superadmin'` row count = 0 ("Bootstrap pending; first /admin/auth/signup becomes superadmin")

### 14.3.2 Sub-Admin Creation (Superadmin Action)

Sub-admins **cannot self-register**. They are created by the superadmin:

```
POST /admin/admins
Authorization: Bearer <superadmin-token>
{
  "email": "moderator@example.com",
  "password": "<initial password>",  // OR omit and send invite link (future)
  "displayName": "Moderator A",
  "permissions": ["scenarios.view", "scenarios.edit", "users.view"]
}
```

**Logic:**
1. Superadmin-only (checked via `@RequireRole('superadmin')`)
2. Creates user with `role='admin'`, `status='active'`
3. Inserts rows into `admin_permissions` table for each permission in the array
4. Validates: every permission key exists in the catalog AND is `grantable_to_subadmin=true`
5. Returns the new admin's profile + granted permissions
6. Audit-logged with `action='admin.create'`, `target_id=newAdminId`, `metadata.permissions=[...]`

- [ ] **14.3.2.1** Email collision returns 409 with clear message
- [ ] **14.3.2.2** Granting an ungrantable permission returns 400 listing the invalid keys
- [ ] **14.3.2.3** Password hashed with same bcrypt cost as user passwords
- [ ] **14.3.2.4** Sub-admin sign-in is the same endpoint as user sign-in (`/auth/signin`) — role is read from DB; JWT payload includes role + permissions list

### 14.3.3 Sub-Admin Sign-in

No separate endpoint. Sub-admins sign in via `/auth/signin` like regular users. The JWT payload is enriched at sign-in time:

```typescript
// JWT payload
{
  sub: userId,
  email: '...',
  role: 'admin' | 'superadmin' | 'user',
  permissions: ['scenarios.view', 'users.view', ...]   // empty for users; full catalog list for superadmin
}
```

On every request, `JwtAuthGuard` validates the token + populates `req.user`. Permission checks read from `req.user.permissions` (fast path) but the source of truth is the DB — see §14.6.3 for the cache-invalidation strategy.

---

## 14.4 Permission Catalog

The catalog is **code-defined** in `backend/src/admin/permissions/catalog.ts` and exposed via `GET /admin/permissions/catalog` for the admin panel to render. Adding a new permission requires editing this file + redeploy.

### 14.4.1 Catalog Schema

```typescript
export interface PermissionDef {
  key: string;                            // 'scenarios.edit'
  category: 'content' | 'users' | 'analytics' | 'system' | 'admin';
  description: string;                    // shown in admin panel UI
  grantable_to_subadmin: boolean;         // false = superadmin-exclusive
  implies?: string[];                     // soft hint for UI (not enforced)
}

export const PERMISSION_CATALOG: PermissionDef[] = [
  // Content management
  { key: 'scenarios.view',        category: 'content', description: 'View all scenarios including drafts and archived', grantable_to_subadmin: true },
  { key: 'scenarios.edit',        category: 'content', description: 'Create, update, publish, archive scenarios',       grantable_to_subadmin: true, implies: ['scenarios.view'] },
  { key: 'scenarios.delete',      category: 'content', description: 'Permanently delete scenarios',                       grantable_to_subadmin: true, implies: ['scenarios.edit'] },
  { key: 'scenarios.upload_image',category: 'content', description: 'Upload hero images for scenarios',                   grantable_to_subadmin: true, implies: ['scenarios.edit'] },
  { key: 'courses.view',          category: 'content', description: 'View all courses',                                   grantable_to_subadmin: true },
  { key: 'courses.edit',          category: 'content', description: 'Create, update, publish, archive courses',           grantable_to_subadmin: true, implies: ['courses.view'] },
  { key: 'courses.delete',        category: 'content', description: 'Permanently delete courses',                         grantable_to_subadmin: true, implies: ['courses.edit'] },
  { key: 'achievements.view',     category: 'content', description: 'View all achievements',                              grantable_to_subadmin: true },
  { key: 'achievements.edit',     category: 'content', description: 'Create and update achievements',                     grantable_to_subadmin: true, implies: ['achievements.view'] },
  { key: 'achievements.grant',    category: 'content', description: 'Manually grant achievements to users',               grantable_to_subadmin: true },
  { key: 'personas.edit',         category: 'content', description: 'Edit persona settings and portraits',                grantable_to_subadmin: true },
  { key: 'wordlist.edit',         category: 'content', description: 'Edit the profanity wordlist (custom.json)',          grantable_to_subadmin: true },

  // User management
  { key: 'users.view',                 category: 'users', description: 'List users and view basic profiles',                            grantable_to_subadmin: true },
  { key: 'users.view_progress',        category: 'users', description: 'View user progress, scores, and skill trends',                  grantable_to_subadmin: true, implies: ['users.view'] },
  { key: 'users.view_sessions',        category: 'users', description: 'View user session history without transcripts',                 grantable_to_subadmin: true, implies: ['users.view'] },
  { key: 'users.view_violations',      category: 'users', description: 'View guard violations (severity and matched terms only)',       grantable_to_subadmin: true, implies: ['users.view'] },
  { key: 'users.view_violations_content', category: 'users', description: 'View full user input flagged by the content guard',          grantable_to_subadmin: false, implies: ['users.view_violations'] },
  { key: 'users.view_transcripts',     category: 'users', description: 'View full conversation transcripts (privacy-sensitive)',        grantable_to_subadmin: false, implies: ['users.view_sessions'] },
  { key: 'users.edit',                 category: 'users', description: 'Edit user profile fields (name, language, theme, persona)',     grantable_to_subadmin: true,  implies: ['users.view'] },
  { key: 'users.edit_role',            category: 'users', description: 'Change a user\'s role (user/admin)',                            grantable_to_subadmin: false, implies: ['users.edit'] },
  { key: 'users.edit_level',           category: 'users', description: 'Manually correct a user\'s English level or XP',                grantable_to_subadmin: false, implies: ['users.edit'] },
  { key: 'users.suspend',              category: 'users', description: 'Suspend and restore users',                                     grantable_to_subadmin: true,  implies: ['users.view'] },
  { key: 'users.delete',               category: 'users', description: 'Soft-delete users',                                             grantable_to_subadmin: false, implies: ['users.view'] },

  // Analytics & audit
  { key: 'stats.view',         category: 'analytics', description: 'View the admin stats dashboard',          grantable_to_subadmin: true },
  { key: 'leaderboard.view',   category: 'analytics', description: 'View user leaderboards',                  grantable_to_subadmin: true },
  { key: 'audit.view',         category: 'analytics', description: 'Search and export the admin audit log',   grantable_to_subadmin: true },

  // System (visibility flags, etc)
  { key: 'config.view',        category: 'system', description: 'View remote-config / visibility flags',      grantable_to_subadmin: true },
  { key: 'config.edit',        category: 'system', description: 'Modify remote-config / visibility flags',    grantable_to_subadmin: true, implies: ['config.view'] },

  // Admin self-management — superadmin only, NEVER grantable
  { key: 'admins.view',           category: 'admin', description: 'List sub-admins and their permissions',       grantable_to_subadmin: false },
  { key: 'admins.create',         category: 'admin', description: 'Create new sub-admin accounts',               grantable_to_subadmin: false },
  { key: 'admins.suspend',        category: 'admin', description: 'Suspend or restore sub-admins',               grantable_to_subadmin: false },
  { key: 'admins.delete',         category: 'admin', description: 'Soft-delete sub-admin accounts',              grantable_to_subadmin: false },
  { key: 'admins.grant_permissions', category: 'admin', description: 'Grant or revoke permissions to sub-admins', grantable_to_subadmin: false },
  { key: 'superadmin.transfer',   category: 'admin', description: 'Transfer the superadmin role to another user', grantable_to_subadmin: false },
];
```

### 14.4.2 Catalog Endpoint

```
GET /admin/permissions/catalog
Authorization: Bearer <any admin token>

→ 200 OK
[
  { "key": "scenarios.view", "category": "content", "description": "...", "grantable_to_subadmin": true, "implies": [] },
  ...
]
```

Used by the future Next.js panel to render the permission-toggle UI. Cacheable for 24 h (catalog only changes on deploy).

- [ ] **14.4.2.1** Endpoint requires `role IN ('admin','superadmin')` but no specific permission (everyone can read the catalog)
- [ ] **14.4.2.2** Response includes ETag based on a hash of the catalog so the panel can cache aggressively

### 14.4.3 Suggested UI Preset Bundles (Panel-side, Not Enforced Backend)

The Next.js panel should offer these as one-click bundles when assigning permissions to a new sub-admin. Backend just stores the resulting individual permissions.

| Preset | Includes |
|--------|----------|
| Content Manager | `scenarios.edit`, `scenarios.upload_image`, `courses.edit`, `achievements.edit`, `achievements.grant`, `personas.edit`, `wordlist.edit` |
| User Moderator | `users.view`, `users.view_violations`, `users.view_sessions`, `users.suspend` |
| Analyst (Read-only) | `users.view`, `users.view_progress`, `stats.view`, `leaderboard.view`, `audit.view` |
| Read-only Everything | All `*.view` permissions across all categories |

---

## 14.5 Database Schema

### admin_permissions (new)

| Column | Type | Constraints | Notes |
|--------|------|-------------|-------|
| user_id | UUID | FK → users.id, ON DELETE CASCADE | sub-admin |
| permission | VARCHAR(60) | NOT NULL | catalog key (e.g. `'scenarios.edit'`) |
| granted_by | UUID | FK → users.id, ON DELETE SET NULL | which superadmin granted |
| granted_at | TIMESTAMPTZ | default now() | |
| PRIMARY KEY | (user_id, permission) | — | composite |

Indexes:
```sql
CREATE INDEX idx_admin_permissions_user ON admin_permissions(user_id);
CREATE INDEX idx_admin_permissions_perm ON admin_permissions(permission);
```

### users (refined semantics, no new columns)

Existing `role` column (from §12) keeps its three-valued domain: `'user'` / `'admin'` / `'superadmin'`. The partial unique index enforces exactly one superadmin at a time:

```sql
CREATE UNIQUE INDEX uniq_one_superadmin ON users (role) WHERE role = 'superadmin';
```

Permission resolution:
- `role='user'` → no permissions (admin panel returns 403 regardless)
- `role='admin'` → permissions are whatever's in `admin_permissions` for this user_id
- `role='superadmin'` → all catalog keys, always (no DB lookup needed)

- [ ] **14.5.1** Migration adds `admin_permissions` table + partial unique index on `role='superadmin'`
- [ ] **14.5.2** Migration is idempotent: running it twice doesn't fail

---

## 14.6 Permission Check Implementation

### 14.6.1 `@RequirePermission()` Decorator

**File:** `backend/src/auth/decorators/require-permission.decorator.ts`

```typescript
export const RequirePermission = (...permissions: string[]) =>
  SetMetadata('permissions', permissions);
```

Usage on a controller method:

```typescript
@Controller('admin/scenarios')
@UseGuards(JwtAuthGuard, PermissionGuard)
export class AdminScenariosController {
  
  @Get()
  @RequirePermission('scenarios.view')
  list() { /* ... */ }
  
  @Post()
  @RequirePermission('scenarios.edit')
  create() { /* ... */ }
  
  @Delete(':id')
  @RequirePermission('scenarios.delete')
  remove() { /* ... */ }
}
```

Multiple permissions = **AND** (user must have all of them). For OR semantics, write the check in the method body.

### 14.6.2 `PermissionGuard`

```typescript
@Injectable()
export class PermissionGuard implements CanActivate {
  constructor(
    private reflector: Reflector,
    private permissions: AdminPermissionsService,
  ) {}

  async canActivate(ctx: ExecutionContext): Promise<boolean> {
    const required = this.reflector.getAllAndOverride<string[]>('permissions', [
      ctx.getHandler(), ctx.getClass()
    ]) ?? [];
    if (required.length === 0) return true;

    const { user } = ctx.switchToHttp().getRequest();
    if (!user) throw new UnauthorizedException();
    if (user.role === 'superadmin') return true;
    if (user.role !== 'admin') throw new ForbiddenException({
      i18nKey: 'admin.not_admin',
      missing: required
    });

    const granted = await this.permissions.getForUser(user.sub);
    const missing = required.filter(p => !granted.has(p));
    if (missing.length > 0) {
      throw new ForbiddenException({
        i18nKey: 'admin.missing_permission',
        missing
      });
    }
    return true;
  }
}
```

The 403 response includes the **missing permission keys** so the future admin panel UI can render "You need: `scenarios.edit`" guidance.

### 14.6.3 `AdminPermissionsService` (with cache)

```typescript
@Injectable()
export class AdminPermissionsService {
  private cache = new Map<string, { perms: Set<string>; at: number }>();
  private readonly TTL_MS = 30_000;   // 30s

  async getForUser(userId: string): Promise<Set<string>> {
    const hit = this.cache.get(userId);
    if (hit && Date.now() - hit.at < this.TTL_MS) return hit.perms;

    const rows = await this.repo.findBy({ user_id: userId });
    const perms = new Set(rows.map(r => r.permission));
    this.cache.set(userId, { perms, at: Date.now() });
    return perms;
  }

  async grant(userId: string, permissions: string[], grantedBy: string) { /* ... + invalidate cache */ }
  async revoke(userId: string, permissions: string[]) { /* ... + invalidate cache */ }
  invalidate(userId: string) { this.cache.delete(userId); }
}
```

- [ ] **14.6.3.1** 30-second in-memory cache — bounded latency between a grant and it taking effect for an in-flight token
- [ ] **14.6.3.2** Grants / revokes immediately invalidate the user's entry
- [ ] **14.6.3.3** When a sub-admin is suspended / deleted, all their `admin_permissions` rows are cascade-deleted (already covered by FK ON DELETE CASCADE on user removal) and the cache entry is invalidated

---

## 14.7 Admin Management Endpoints (Superadmin-only)

All require `role='superadmin'`. None of these are grantable to sub-admins.

| Method | Path | Permission | Purpose |
|--------|------|-----------|---------|
| GET | `/admin/admins` | `admins.view` | List all sub-admins with their permissions |
| GET | `/admin/admins/:id` | `admins.view` | Single sub-admin detail |
| POST | `/admin/admins` | `admins.create` | Create a new sub-admin with initial permission set |
| PUT | `/admin/admins/:id/permissions` | `admins.grant_permissions` | Replace the permission set (idempotent) |
| POST | `/admin/admins/:id/permissions/:perm` | `admins.grant_permissions` | Grant single permission |
| DELETE | `/admin/admins/:id/permissions/:perm` | `admins.grant_permissions` | Revoke single permission |
| POST | `/admin/admins/:id/suspend` | `admins.suspend` | Suspend a sub-admin |
| POST | `/admin/admins/:id/restore` | `admins.suspend` | Restore a suspended sub-admin |
| DELETE | `/admin/admins/:id` | `admins.delete` | Soft-delete a sub-admin |
| POST | `/admin/superadmin/transfer` | `superadmin.transfer` | Transfer superadmin role (two-step, see §14.9) |

- [ ] **14.7.1** All endpoints audit-logged with `target_type='user'`, `target_id=adminId`, `action='admin.<verb>'`
- [ ] **14.7.2** Cannot delete / suspend / demote oneself (superadmin can't lock themselves out)
- [ ] **14.7.3** PUT / POST / DELETE on `:id/permissions` rejects when target user is not `role='admin'` (e.g. trying to grant to a regular user)
- [ ] **14.7.4** Grant validation: rejects 400 if any requested permission has `grantable_to_subadmin=false` in the catalog

---

## 14.8 Per-Endpoint Permission Map

The authoritative mapping for every admin endpoint defined in §12 and §13. This table drives the `@RequirePermission` decorations.

| Endpoint | Required Permission |
|----------|---------------------|
| `GET /app-config` | (no admin permission — any authenticated user) |
| `GET /admin/config` | `config.view` |
| `GET /admin/config/:key` | `config.view` |
| `PATCH /admin/config/:key` | `config.edit` |
| `POST /admin/config/reset/:key` | `config.edit` |
| `POST /admin/config/reset-all` | (superadmin only — no permission key) |
| `GET /admin/config/audit` | `audit.view` |
| `GET /admin/scenarios` | `scenarios.view` |
| `GET /admin/scenarios/:id` | `scenarios.view` |
| `POST /admin/scenarios` | `scenarios.edit` |
| `PATCH /admin/scenarios/:id` | `scenarios.edit` |
| `POST /admin/scenarios/:id/publish` | `scenarios.edit` |
| `POST /admin/scenarios/:id/archive` | `scenarios.edit` |
| `DELETE /admin/scenarios/:id` | `scenarios.delete` |
| `POST /admin/scenarios/:id/image` | `scenarios.upload_image` |
| `DELETE /admin/scenarios/:id/image` | `scenarios.upload_image` |
| `POST /admin/scenarios/:id/test` | `scenarios.edit` |
| `GET /admin/courses` | `courses.view` |
| `POST/PATCH/PUBLISH/ARCHIVE /admin/courses/*` | `courses.edit` |
| `DELETE /admin/courses/:id` | `courses.delete` |
| `GET /admin/achievements` | `achievements.view` |
| `POST/PATCH /admin/achievements` | `achievements.edit` |
| `DELETE /admin/achievements/:id` | `achievements.edit` (note: per §13.2.3, hard-delete is admin-allowed only if no users earned it) |
| `POST /admin/users/:uid/achievements/:aid/grant` | `achievements.grant` |
| `DELETE /admin/users/:uid/achievements/:aid` | `achievements.grant` |
| `PATCH /admin/personas/:id` | `personas.edit` |
| `POST /admin/personas/:id/image` | `personas.edit` |
| `POST /admin/personas/:id/(de)activate` | `personas.edit` |
| `GET /admin/users` | `users.view` |
| `GET /admin/users/:id` | `users.view` |
| `PATCH /admin/users/:id` (non-role fields) | `users.edit` |
| `PATCH /admin/users/:id` (role field) | `users.edit_role` (superadmin-only) |
| `PATCH /admin/users/:id` (level/xp fields) | `users.edit_level` (superadmin-only) |
| `POST /admin/users/:id/suspend` | `users.suspend` |
| `POST /admin/users/:id/restore` | `users.suspend` |
| `DELETE /admin/users/:id` | `users.delete` (superadmin-only) |
| `GET /admin/users/:id/sessions` | `users.view_sessions` |
| `GET /admin/users/:id/scores/trend` | `users.view_progress` |
| `GET /admin/users/:id/skills/snapshots` | `users.view_progress` |
| `GET /admin/users/:id/violations` (severity + terms only) | `users.view_violations` |
| `GET /admin/users/:id/violations` (with content field) | `users.view_violations_content` (superadmin-only) |
| `GET /admin/users/:uid/sessions/:sid/transcript` | `users.view_transcripts` (superadmin-only) |
| `GET /admin/leaderboard` | `leaderboard.view` |
| `GET /admin/stats` | `stats.view` |
| `GET /admin/audit` | `audit.view` |
| `GET /admin/audit/export` | `audit.view` |
| `DELETE /admin/audit?before=...` | (superadmin-only) |
| `GET /admin/guard/wordlists` | `wordlist.edit` |
| `PATCH /admin/guard/wordlists/custom` | `wordlist.edit` |
| `POST /admin/guard/reload` | `wordlist.edit` |
| `GET /admin/permissions/catalog` | (any admin or superadmin) |
| `GET /admin/admins/*` | `admins.view` (superadmin-only) |
| `POST /admin/admins` | `admins.create` (superadmin-only) |
| `PUT /admin/admins/:id/permissions` | `admins.grant_permissions` (superadmin-only) |
| `POST/DELETE /admin/admins/:id/permissions/:p` | `admins.grant_permissions` (superadmin-only) |
| `POST /admin/admins/:id/(suspend|restore)` | `admins.suspend` (superadmin-only) |
| `DELETE /admin/admins/:id` | `admins.delete` (superadmin-only) |
| `POST /admin/superadmin/transfer` | `superadmin.transfer` (superadmin-only) |

- [ ] **14.8.1** Every admin controller method has `@RequirePermission(...)` per this table
- [ ] **14.8.2** Integration tests verify a sub-admin without the permission gets 403 + missing key
- [ ] **14.8.3** Integration tests verify the superadmin can hit every endpoint regardless

---

## 14.9 Superadmin Transfer

Transferring superadmin is **destructive** to the current holder's authority. Spec'd as a two-step confirmation:

```
Step 1:
POST /admin/superadmin/transfer
{ "targetUserId": "<uuid>" }

→ 200 OK
{ "confirmationToken": "<short-lived JWT, 5min>" }

Step 2:
POST /admin/superadmin/transfer/confirm
{ "confirmationToken": "<from step 1>", "passwordReauth": "<current superadmin password>" }

→ 200 OK
{ "newSuperadminId": "...", "demotedTo": "admin" }
```

Effects:
- Target must currently have `role='admin'` (cannot promote a regular user — promote-then-transfer is a two-step deliberately)
- Current superadmin becomes `role='admin'` with their previous `admin_permissions` retained
- Target becomes `role='superadmin'`; their existing `admin_permissions` rows are deleted (irrelevant for superadmin)
- Both users' tokens are revoked; both must sign in again
- Audit log records both halves of the transfer with cross-references

- [ ] **14.9.1** Confirmation token is single-use, short-lived (5 min), tied to the same user-agent + ip
- [ ] **14.9.2** Password re-auth required in step 2 (defense against compromised access token)
- [ ] **14.9.3** Failed confirmation (wrong password, expired token) audit-logged as `superadmin.transfer.failed`
- [ ] **14.9.4** Database transaction: both role flips happen in one TX (partial unique index would otherwise reject)

---

## 14.10 Audit Coverage

Every action listed in §14.7 records to `admin_audit_log` (defined in [13 §13.8.2](13_admin_content_and_users.md)).

| Action | Notes |
|--------|-------|
| `admin.bootstrap` | Initial superadmin sign-up |
| `admin.create` | Sub-admin created; `metadata.permissions` lists initial grants |
| `admin.permission.grant` | Single permission granted; metadata includes the permission key |
| `admin.permission.revoke` | Single permission revoked |
| `admin.permissions.replace` | Bulk replacement via PUT; old + new permission sets in old_value / new_value |
| `admin.suspend` / `admin.restore` | Reason in metadata |
| `admin.delete` | Soft delete |
| `superadmin.transfer.initiated` | Step 1; metadata.targetUserId |
| `superadmin.transfer.completed` | Step 2; both users in metadata |
| `superadmin.transfer.failed` | Step 2 failure (wrong password / expired token) |

- [ ] **14.10.1** Audit interceptor applies the same `@AuditAction(...)` decorator from §13.8 to admin-management endpoints

---

## 14.11 App-Side Awareness

Mostly irrelevant — admins use the Next.js panel, not the Flutter app. But a few touchpoints:

- [ ] **14.11.1** Sub-admin / superadmin can also sign in to the Flutter app (same `/auth/signin`); the Flutter app simply ignores their `role` and shows the normal user UI
- [ ] **14.11.2** Suspended admin → same 401 + `account.suspended` error as suspended user
- [ ] **14.11.3** No admin-panel UI inside the Flutter app — the Next.js panel is a separate web app
- [ ] **14.11.4** New i18n keys for admin endpoints used by the Flutter app: none (admin endpoints are not called by the Flutter app at all in v1)

---

## 14.12 Implementation Checklist (Backend, v1)

- [ ] **14.12.1** Migration: create `admin_permissions` table + indexes + partial unique index on `users.role='superadmin'`
- [ ] **14.12.2** `backend/src/admin/permissions/catalog.ts` — the canonical `PERMISSION_CATALOG` constant
- [ ] **14.12.3** `AdminPermissionsService` with TTL cache + grant / revoke / replace / invalidate
- [ ] **14.12.4** `@RequirePermission()` decorator + `PermissionGuard`
- [ ] **14.12.5** `AdminAdminsController` — full CRUD on sub-admins + permission grant/revoke endpoints
- [ ] **14.12.6** `AdminAuthController` — `POST /admin/auth/signup` bootstrap endpoint (auto-closes after first admin)
- [ ] **14.12.7** Superadmin transfer two-step endpoints with confirmation token
- [ ] **14.12.8** JWT payload enriched with `role` + `permissions` on issue
- [ ] **14.12.9** Apply `@RequirePermission(...)` to every admin controller method per the §14.8 mapping table
- [ ] **14.12.10** Update existing §12 + §13 controllers to use `@RequirePermission` instead of role-only checks
- [ ] **14.12.11** Integration tests: bootstrap flow, sub-admin grant/revoke, missing-permission 403 shape, superadmin transfer happy path + failure paths
- [ ] **14.12.12** Seed: a permissions-catalog-print script that dumps the current catalog as a Markdown table (regenerated on every catalog change, committed for visibility)

## 14.13 Future Considerations (Out of Scope for v1)

| Idea | Why deferred |
|------|--------------|
| Permission groups / roles (named bundles) | Backend stores flat permissions; panel UI handles "preset" bundles as syntactic sugar |
| Multi-superadmin / break-glass | One superadmin per system avoids audit ambiguity; if needed later, add a separate "guardian" mechanism |
| Time-bound / scheduled permissions | Manual revoke is fine for v1; add expires_at column when justified |
| Per-resource permissions (e.g. "can edit scenario X but not Y") | Coarser permissions are sufficient for v1; add ABAC layer when justified |
| Email-invite flow for new sub-admins (token + set-password link) | v1 has the superadmin set the initial password directly; invite-link flow is a UX polish |
| OAuth / SSO for admins | v1 uses password auth; SSO is a future enterprise feature |
| Permission audit dashboard (panel-side) | The audit endpoints exist; rendering them is a panel feature |
