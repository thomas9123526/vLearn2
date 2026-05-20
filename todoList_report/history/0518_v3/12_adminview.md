# 12_adminview — Collapsible admin cards on the Admins page

## Ask

> I want simple view for Admins tab of admin panel. It shows many checkboxes for
> "Initial permissions", So I want show simple list view that list all the admins.
> Item view will be like card view. And if the superadmin taps the card view, it
> uncollapsed to show full details like checkboxes for "Initial permissions".

---

## Before

Every admin card had `CardContent` always visible, showing either:
- "Superadmin has all permissions implicitly." text, or
- The full `PermissionGrid` with all checkbox categories

On a team with many admins this meant a very long page dominated by permission checkboxes.

## After

Each admin row is a card that shows only the summary by default. A chevron button in the
top-right corner expands/collapses the detail panel:

```
┌─────────────────────────────────────────────────────────┐
│  Alice Kim                             [Suspend] [▼]    │
│  alice@example.com · Admin · active                     │
└─────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────┐
│  Bob Lee                                        [▲]     │
│  bob@example.com · Admin · active                       │
├─────────────────────────────────────────────────────────┤
│  ┌──────────────────┐  ┌──────────────────┐            │
│  │ users            │  │ content           │            │
│  │ ☑ users.view     │  │ ☑ content.view    │            │
│  │ ☐ users.ban      │  │ ☐ content.delete  │            │
│  └──────────────────┘  └──────────────────┘            │
└─────────────────────────────────────────────────────────┘
```

### `AdminCard` component (new, extracted)

The per-row rendering was moved into its own `AdminCard` function component with local
`const [expanded, setExpanded] = useState(false)` state. Key decisions:

- **Chevron button** is shown only when there is something to expand (`canGrant` or
  the row is a superadmin). Ordinary admins with no grant permission don't see the toggle
  since they can't change anything anyway.
- **Status colour**: `text-green-600` for active, `text-yellow-600` for suspended,
  `text-muted-foreground` for deleted — makes the status scannable at a glance.
- **`CardContent`** is conditionally rendered (`{expanded && <CardContent>…</CardContent>}`)
  with a top-border divider to visually separate it from the header.

The `PermissionGrid` and `CreateSubAdminForm` components are unchanged; they just moved
into the same file alongside `AdminCard`.

---

## Files changed

| File | Change |
|------|--------|
| [admin_panel/src/app/(dashboard)/admins/page.tsx](../../admin_panel/src/app/(dashboard)/admins/page.tsx) | Extracted `AdminCard` with `expanded` state; permissions hidden by default behind chevron toggle; `ChevronDown`/`ChevronUp` icons added |
