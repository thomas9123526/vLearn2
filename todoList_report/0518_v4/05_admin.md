# Task Report — 05_admin (card view + Edit Permission dialog)

**Date:** 2026-05-19
**Branch:** `dev`

## Requirement

> On the **Admins** tab, the page shows information with many checkboxes.
> I want a simple card per admin, and if the user taps **Edit Permission**
> a permission dialog opens with the checkbox grid.

## What changed

### New reusable Dialog component

`admin_panel/src/components/ui/dialog.tsx` — small portal-based modal with
backdrop, Escape-to-close, optional header/footer slots. No external
dependency. Designed so future admin CRUD flows can reuse it without
dragging in Headless UI / Radix today.

```
<Dialog open={...} onClose={...} title="..." footer={<>...</>}>
  ...
</Dialog>
```

### Admins page refactored

`admin_panel/src/app/(dashboard)/admins/page.tsx` rewritten:

| Before | After |
|---|---|
| One vertical list. Each admin row had a chevron that **expanded inline**, dumping the whole 4-category permission grid into the page. With more than a couple of sub-admins the page became a wall of checkboxes. | A **responsive grid of cards** (1 / 2 / 3 columns depending on viewport). Each card shows just identity (`display_name`, `email`), `Role`, `Status`, `# permissions granted`, plus action buttons. |
| Permissions edited inline with no save/cancel — every checkbox click hit the API. | **Edit Permission** button per card opens the dialog with the current grid. Local selection state lives inside the dialog; the actual save fires only on the **Save** button (with a **Cancel** that discards changes). |
| **Create sub-admin** form rendered the whole permission grid below the password field. | Compact create form shows `N selected` with a **Choose permissions** button that opens the same dialog. |

### Behavioural details

- The dialog tracks its own pending `selection` state. On cancel / backdrop click / Escape the pending changes are discarded and the API row is unchanged.
- The Save button is disabled while the mutation is in flight (`replacePerms.isPending`).
- Superadmins **do not** show an Edit Permission button (their permissions are implicit and the API doesn't support assigning them). The card shows `all (implicit)` instead of the count.
- Suspended sub-admins still surface a **Restore** button. Active ones still surface **Suspend**. No regression to the lifecycle actions.
- `Edit Permission` is gated on `admins.grant_permissions`. The dialog itself respects `disabled` so a viewer with read access can open it but not toggle anything.

### Permission grid component

The previous in-file `PermissionGrid` was reused verbatim, just hoisted
into the dialog body. The category groupings, label / description
columns, and `grantable_to_subadmin` filter all behave exactly as before.

### Empty-catalog handling

If the catalog query hasn't loaded yet, the grid now renders
`"Permission catalog not loaded yet."` instead of an empty `<div>`, so
the user has a clear cue rather than a silently empty modal.

---

## Files touched

```
admin_panel/src/components/ui/dialog.tsx           (new — reusable modal)
admin_panel/src/app/(dashboard)/admins/page.tsx    (rewrite)
```

No backend changes were required — `PUT /admin/admins/:id/permissions`
already accepts a full permission array, which is exactly what the dialog
sends on Save.

## Verification

- Admin panel `tsc --noEmit`: clean.
- Manual walk-through:
  - Card grid renders three columns on wide screens, collapses to one on mobile.
  - Click **Edit Permission** → dialog opens with current selection pre-checked.
  - Toggle a few boxes → click **Cancel** → reopen → original selection unchanged. ✓
  - Toggle → **Save** → dialog closes, card's "Permissions" count updates after the query refetches. ✓
  - Escape closes the dialog. Backdrop click closes the dialog. Click inside the panel does not close. ✓
  - Superadmin cards show no **Edit Permission** button. ✓
  - "Create sub-admin" form: clicking **Choose permissions** opens the same dialog; selecting and clicking **Done** updates the `N selected` indicator. ✓
