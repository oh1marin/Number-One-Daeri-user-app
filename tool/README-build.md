# Build (Android AAB) shortcuts

## Production AAB (always inject API_BASE_URL)

PowerShell:

```powershell
.\tool\build_aab_prod.ps1 -ApiBaseUrl https://YOUR-PROD-HOST/api/v1/
```

Or set env var once (recommended for your machine):

```powershell
setx API_BASE_URL https://YOUR-PROD-HOST/api/v1/
```

Then:

```powershell
.\tool\build_aab_prod.ps1
```

Output:

`build/app/outputs/bundle/release/app-release.aab`

## Current default (project)

If you run the script with no params and no `API_BASE_URL` env var set, it uses:

`https://api.xn--zb0bu7iuubp7hba523s.kr/api/v1/`

