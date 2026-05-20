# 04_tutor_edit — Edit function for tutors in admin panel

## Ask

> I want add edit function for tutor in admin panel.

## What existed

The personas list page (`/personas`) linked the **name column** to `/personas/[id]` where a full edit form already lived. However, the link was subtle — just an underline on hover — and the actions column only showed **Deactivate / Restore** buttons. There was no explicit "Edit" button.

## What changed

### `admin_panel/src/app/(dashboard)/personas/page.tsx`

Added a `Pencil` icon button to the actions cell of every row. It links to the detail/edit page and respects the existing `canEdit` permission gate:

```tsx
import { Pencil, Plus, Power, RotateCcw } from 'lucide-react';

// In the actions <td>:
<div className="flex items-center justify-end gap-1">
  {canEdit && (
    <Link href={`/personas/${p.id}`}>
      <Button size="sm" variant="ghost">
        <Pencil className="h-4 w-4" />
        Edit
      </Button>
    </Link>
  )}
  {canEdit && (p.is_active ? <Deactivate …> : <Restore …>)}
</div>
```

The three action buttons (Edit, Deactivate/Restore) now sit side by side with `flex items-center justify-end gap-1`.

## The edit form (unchanged)

The existing `admin_panel/src/app/(dashboard)/personas/[id]/page.tsx` was already complete:

| Field | Type |
|-------|------|
| Slug | text (validated lowercase + dashes) |
| Display name | text |
| Accent | text |
| Style | text |
| Specialties | comma-separated text → stored as `string[]` |
| Gender | select: neutral / female / male |
| TTS voice ID | text (optional) |
| Rive asset | text (optional) |
| Gradient from/to | hex color inputs |
| Portrait image | file upload (JPEG/PNG/WebP, max 5 MB) |

On save: `PATCH /admin/personas/:id` updates the text fields; a second `POST /admin/personas/:id/image` request handles the image upload if a file was selected. The preview card on the right shows the gradient + image live from the DB.

## Files changed

| File | Change |
|------|--------|
| [admin_panel/src/app/(dashboard)/personas/page.tsx](../../admin_panel/src/app/(dashboard)/personas/page.tsx) | Added `Pencil` import + Edit button in actions column |
