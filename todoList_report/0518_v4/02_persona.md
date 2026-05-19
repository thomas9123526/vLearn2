# Task Report — 02_persona (full admin-panel audit)

**Date:** 2026-05-19
**Commit:** `c221184`
**Branch:** `dev`

---

## Requirement

> Check all the pages on the admin panel and see if there's any errors.
> Resolve any error. Backend changes are OK if needed to make all pages work.

## Audit summary

15 routes were inspected across the dashboard.

| Route | Status | Notes |
|---|---|---|
| `/` (Dashboard) | ✓ | Loads `/admin/stats` counters; correct error fallback. |
| `/personas` | ✓ | List + soft-delete + restore work. |
| `/personas/new` | ✗ → ✓ | Form ref bug (see below). Fixed. |
| `/personas/[id]` | ✗ → ✓ | Form ref bug — root cause for task 03. Fixed. |
| `/scenarios` | ⚠ → ✓ | List worked but linked to a 404. Fixed by demoting title to plain text. |
| `/scenarios/new` | ✗ → ✓ | Same form ref bug. Fixed. |
| `/scenarios/[id]` | n/a | Route doesn't exist. Edit page not built yet; out of scope. |
| `/users` | ✓ | Search / suspend / restore all work. |
| `/news` + `/news/new` | ✓ | Forms use `Input` directly with `register` — no Field wrapper, no bug. |
| `/leaderboard` | ✓ | Metric / language / limit filters work. |
| `/audit` | ✓ (stub) | Page is an intentional placeholder until `/admin/audit` ships. |
| `/admins` | ✓ | Uses controlled `useState` inputs, immune to the Field bug. |
| `/config` | ✓ | Big/fine flag grid + orphan section all render. |
| `/settings` | ✓ | gzip toggle + session info. |
| Sign-in / sign-up | ✓ | Use `Input` directly; correct. |

---

## Root cause for the form bugs

`personas/[id]/page.tsx`, `personas/new/page.tsx`, and `scenarios/new/page.tsx`
each defined a private helper component to compose `<Label>` + `<Input>` +
inline error text:

```tsx
const Field = ({ id, label, error, ...rest }: ...) => (
  <div>
    <Label htmlFor={id}>{label}</Label>
    <Input id={id} {...rest} />
    {error && <p>{error}</p>}
  </div>
);
```

`Field` is a **plain function component**, not a `React.forwardRef`. When
the caller does `<Field {...register('slug')} />`, react-hook-form's
`register()` returns `{ onChange, onBlur, name, ref }` — the `ref` lands on
`Field`'s props, gets silently dropped, and never reaches the underlying
`<input>`.

Consequences:

- `onChange` still fires → form state stays in sync while typing.
- `setValue()` updates internal state but cannot write to the DOM input.
- **`reset()` cannot write to the DOM input** → the form stays blank when
  API data lands.
- `defaultValues` are also broken for these specific fields.

## Fix

Converted `Field` to `React.forwardRef` in all three pages, passing the
ref through to the `<Input>`:

```tsx
const Field = forwardRef<HTMLInputElement, FieldProps>(
  ({ id, label, error, ...rest }, ref) => (
    <div>
      <Label htmlFor={id}>{label}</Label>
      <Input id={id} ref={ref} {...rest} />
      {error && <p>{error}</p>}
    </div>
  ),
);
Field.displayName = 'Field';
```

## Other findings

### `/scenarios` list linked to 404

[scenarios/page.tsx:77](admin_panel/src/app/(dashboard)/scenarios/page.tsx#L77)
wrapped each scenario title in `<Link href={'/scenarios/${s.id}'}>`, but
`/scenarios/[id]/page.tsx` doesn't exist. Clicking a title produced a
Next.js 404. Demoted the title to plain `<span>` for now, with a comment
to re-enable when the edit page is built. Publish / archive / delete still
work from the list, so no functional regression.

### Type drift around nullable email

`/users` and `/leaderboard` TypeScript interfaces declare `email: string`,
but after the recent `vl_user_info` extraction the backend can return
`null` for users created without an email (CID-only signups). Today this
just renders an empty cell — no crash — so I left it; tighten the type to
`string | null` when we decide what UX we want for those rows.

### `/audit` is a placeholder

Documented in the page itself — `vl_admin_audit_log` table exists but no
`/admin/audit` endpoint. Not an error per the user's wording.

---

## Verification

- Backend `tsc --noEmit`: clean.
- Admin-panel `tsc --noEmit`: clean.
- Unit tests pass.
- Manually traced every form path; no other components shadow react-hook-form's ref.

---

## Files touched

```
admin_panel/src/app/(dashboard)/personas/[id]/page.tsx   (Field → forwardRef)
admin_panel/src/app/(dashboard)/personas/new/page.tsx    (Field → forwardRef)
admin_panel/src/app/(dashboard)/scenarios/new/page.tsx   (Field → forwardRef)
admin_panel/src/app/(dashboard)/scenarios/page.tsx       (drop 404 link)
```

No backend changes were required for this task.
