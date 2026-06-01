# I want remove email, xp on http://localhost:4101/vAdmin/users/ per user

Session: `90c5c6ba-f941-45bb-8889-37114ea77f9f`
Saved: 2026-06-01T09:35:04.915Z

## User

I want remove email, xp on http://localhost:4101/vAdmin/users/ per user

## Assistant

Let me find the admin users page code.

## Assistant

I can see the table structure. I'll remove the Email column (header + cell) and XP column (header + cell), and fix the `colSpan` count.

## Assistant

Now fix the `colSpan` — was 8/6, now should be 6/4 (removed 2 columns):

## Assistant

Now commit:

## Assistant

Done. Removed the **Email** and **XP** columns from the users table — both the `<th>` headers and `<td>` cells — and updated the empty-state `colSpan` from 8/6 to 6/4. Changes committed.
