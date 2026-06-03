# I want downgrade node version of the backend and admin_panel from 22 to 18.20.8.

Session: `3fb0e8c5-c4b4-421d-97a4-d9e9c530c1a6`
Saved: 2026-06-01T17:37:45.270Z

## User

I want downgrade node version of the backend and admin_panel from 22 to 18.20.8. I already installed node v18.20.8

## Assistant

No `engines` field exists yet in either package. I'll add it to both `package.json` files and create `.nvmrc` files in each directory.

## Assistant

Now create `.nvmrc` in both directories:

## Assistant

Now commit and save the story:

## Assistant

Done. Two things were added:

- **`.nvmrc`** in both `backend/` and `admin_panel/` — `nvm use` will automatically switch to 18.20.8 when you `cd` into either directory.
- **`engines` field** in both `package.json` files — `npm install` will warn if someone runs it with the wrong Node version.

The range `>=18.20.8 <19 || >=20` skips the odd-numbered 19.x release (never an LTS) so it won't break if you later move to Node 20 LTS.

To switch now on your machine (if using nvm):
```bash
nvm use   # inside backend/ or admin_panel/ — picks up .nvmrc automatically
```
