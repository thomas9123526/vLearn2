# Task Report — 99_test

**Date:** 2026-05-19

## Requirement

> On the Tutors tab of the admin panel, when I click **Edit**, the edit
> tutor dialog opens but doesn't have the editor's information filled in.

## Status: already fixed (duplicate of `03_admin_unittest`)

The body of `99_test` is byte-for-byte identical to `03_admin_unittest`.
The fix landed in commit **`c221184`** alongside the earlier batch.

## Recap of the fix

The persona edit page wraps each input in a private `Field` helper. That
helper was a plain function component, so the `ref` produced by
`register('slug')` (and every other `register()` call) never reached the
underlying `<input>`. Without that ref, react-hook-form's `reset()` could
update its internal state when the API response landed but couldn't
write the values back to the DOM — the inputs stayed visibly empty even
though the form "knew" the values.

Converting `Field` to `React.forwardRef` and threading the ref to the
inner `<Input>` resolved it. Same bug existed (and was fixed) in
`personas/new/page.tsx` and `scenarios/new/page.tsx` as a precaution.

See [03_admin_unittest.md](03_admin_unittest.md) for the full diagnosis.

## Verification

- Admin panel `tsc --noEmit`: clean.
- Manual: clicking **Edit** on a tutor row now opens the editor with
  every field pre-filled from the API response.
