# can you make print out all the packages that must be installed for run this vLea

Session: `cb14393c-1d33-4891-aee0-276d4c902efe`
Saved: 2026-06-04T07:06:28.031Z

## User

can you make print out all the packages that must be installed for run this vLearn2 project? for windows first.

## Assistant

Let me read the dependency files across all three sub-projects.

## Assistant

Here's the complete package/tool list for running vLearn2 on Windows:

---

## System tools (install manually)

| Tool | Version | Purpose |
|---|---|---|
| **Flutter SDK** | ≥ 3.11.5 | Flutter app + Dart SDK |
| **Node.js** | ≥ 18.20.8 or ≥ 20 | Backend (NestJS) + Admin panel (Next.js) |
| **Git** | any | Source control |
| **Visual Studio Build Tools 2022** | 2022 | Windows desktop Flutter build (CMake, MSBuild, Ninja) — workload: "Desktop development with C++" |
| **PostgreSQL** | 14+ | Backend database (or Docker Desktop + `docker compose up`) |
| **Docker Desktop** | any | Optional — only if you use `docker compose` for Postgres |
| **Android Studio / Android SDK** | API 33+ | APK builds / device debugging |

---

## Flutter app — `flutter pub get` (flutter_app/)

**Runtime deps:**
```
flutter_riverpod ^2.5.1        # state management
riverpod_annotation ^2.3.5
go_router ^14.2.0              # navigation
dio ^5.4.3+1                   # HTTP
retrofit ^4.1.0
pretty_dio_logger ^1.4.0
drift ^2.18.0                  # local SQLite ORM
sqlite3_flutter_libs ^0.5.22   # SQLite native libs
path_provider ^2.1.3
path ^1.9.0
freezed_annotation ^2.4.2
json_annotation ^4.9.0
rive ^0.14.7                   # avatar animation
intl ^0.20.2
cupertino_icons ^1.0.8
cached_network_image ^3.3.1
flutter_svg ^2.0.10+1
fl_chart ^0.68.0
connectivity_plus ^6.0.5
image_picker ^1.1.2
shared_preferences ^2.2.3
flutter_secure_storage ^9.2.2
logger ^2.3.0
collection ^1.18.0
crypto ^3.0.3
equatable ^2.0.5
package_info_plus ^8.0.0
device_info_plus ^10.1.0
pointycastle ^3.9.1            # AES-GCM / ECDH for .ddp decrypt
archive ^3.6.1
asn1lib ^1.6.0
sherpa_onnx ^1.13.0            # on-device STT + TTS (ONNX runtime)
permission_handler ^11.3.1
record ^6.0.0                  # mic capture
audioplayers ^6.0.0            # WAV playback
```

**Dev deps** (codegen — run `dart run build_runner build`):
```
build_runner ^2.4.11
riverpod_generator ^2.4.0
custom_lint ^0.6.4
riverpod_lint ^2.3.10
drift_dev ^2.18.0
freezed ^2.5.2
json_serializable ^6.8.0
flutter_native_splash ^2.4.4
flutter_lints ^6.0.0
```

---

## Backend (NestJS) — `npm install` (backend/)

```
@nestjs/common ^11.0.1
@nestjs/core ^11.0.1
@nestjs/config ^4.0.4
@nestjs/jwt ^11.0.2
@nestjs/passport ^11.0.5
@nestjs/platform-express ^11.0.1
@nestjs/swagger ^11.4.3
@nestjs/throttler ^6.5.0
@nestjs/typeorm ^11.0.1
@anthropic-ai/sdk ^0.96.0      # Claude API
openai ^6.38.0
typeorm ^0.3.29
pg ^8.20.0                     # PostgreSQL driver
bcrypt ^6.0.0
passport ^0.7.0
passport-jwt ^4.0.1
passport-local ^1.0.0
class-transformer ^0.5.1
class-validator ^0.15.1
compression ^1.8.1
helmet ^8.1.0
nestjs-i18n ^10.8.4
sharp ^0.34.5
dotenv ^17.4.2
reflect-metadata ^0.2.2
rxjs ^7.8.1
uuid ^14.0.0
```

Dev: `@nestjs/cli`, `typescript`, `ts-node`, `jest`, `prettier`, `eslint`, etc. — all installed by `npm install`.

---

## Admin panel (Next.js) — `npm install` (admin_panel/)

```
next ^14.2.35
react 18.3.1
react-dom 18.3.1
next-intl ^4.13.0
@tanstack/react-query ^5.51.0
@tanstack/react-table ^8.20.0
@hookform/resolvers ^3.9.0
react-hook-form ^7.52.0
recharts ^2.12.7
lucide-react ^0.426.0
date-fns ^3.6.0
clsx ^2.1.1
tailwind-merge ^2.4.0
class-variance-authority ^0.7.0
zod ^3.23.8
```

Dev: `tailwindcss`, `postcss`, `autoprefixer`, `typescript`, `eslint`, `playwright`, `jest`.

---

## Windows desktop build — offline-only extras

These are **not** in the package registries — place manually in the repo (gitignored):

| File | Path | Source |
|---|---|---|
| `nuget.exe` v6.5.0 | `flutter_app/windows/nuget/nuget.exe` | dist.nuget.org |
| `microsoft.windows.implementationlibrary.1.0.210803.1.nupkg` | `flutter_app/windows/nuget_feed/` | nuget.org |
| `microsoft.windows.cppwinrt.2.0.210806.1.nupkg` | `flutter_app/windows/nuget_feed/` | nuget.org |
| `sqlite-autoconf-3520000` (extracted) | `flutter_app/windows/sqlite3_src/` | sqlite.org |

And set in `%AppData%\NuGet\NuGet.Config` on the offline VM with an absolute path to the `nuget_feed/` folder.

---

## Quick-start commands

```powershell
# Flutter app
cd flutter_app
flutter pub get
dart run build_runner build --delete-conflicting-outputs
flutter run -d windows          # desktop
flutter run -d <device-id>      # Android

# Backend
cd backend
npm install
# copy .env.example -> .env and fill in values
npm run db:migrate
npm run start:dev

# Admin panel
cd admin_panel
npm install
npm run dev
```
