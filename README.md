# hitch_db

Flutter client for HitchDB.

## Environment files

Create a local `env/app.env` file.

Use `env/app.env.example` as the template:

```env
API_BASE_URL=http://localhost:5264
TMDB_API_KEY=your_tmdb_api_key_here
```

Security behavior:

- `env/*.env` is gitignored.
- `env/*.env.example` is tracked for onboarding.

## Backend login contract

The app signs in against the .NET backend endpoint below:

- `POST /api/Auth/login`
- JSON body: `{"email":"user@example.com","password":"secret"}`
- Success response: `{"token":"<jwt>"}`

By default the Flutter app targets `http://localhost:5264`, which matches the backend launch profile in development.

Override the backend URL when needed with a Dart define:

```bash
flutter run --dart-define=API_BASE_URL=http://localhost:5264
```

For Android emulators, use `http://10.0.2.2:5264` unless you have a different tunnel or host mapping.
