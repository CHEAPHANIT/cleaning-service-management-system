# CleanNow SQLite API

Start the shared backend before running Flutter:

```powershell
python server/clean_now_api.py
```

The API listens on `http://localhost:8080/api` and stores shared data in
`server/cleannow_server.db`.

Interactive Swagger documentation is available after startup at:

```text
http://localhost:8080/docs
```

The OpenAPI 3 specification is served at `http://localhost:8080/openapi.json`.
Swagger's **Try it out** actions call the current server directly.

Cleaner credentials are chosen in the cleaner application form and become active after administrator approval. Only the administrator demo credential is seeded.

For another host or port, run Flutter with:

```powershell
flutter run -d chrome --web-port 55226 --dart-define=CLEAN_NOW_API_URL=http://localhost:8080/api
```

Android emulator uses the host alias:

```powershell
flutter run --dart-define=CLEAN_NOW_API_URL=http://10.0.2.2:8080/api
```
