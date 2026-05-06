param(
  [string]$ApiBaseUrl = "",
  [string]$BuildName = "",
  [string]$BuildNumber = ""
)

$ErrorActionPreference = "Stop"

function Ensure-TrailingSlash([string]$url) {
  if ([string]::IsNullOrWhiteSpace($url)) { return $url }
  if ($url.EndsWith("/")) { return $url }
  return "$url/"
}

function Normalize-ApiBaseUrl([string]$url) {
  if ([string]::IsNullOrWhiteSpace($url)) { return $url }
  $u = Ensure-TrailingSlash $url
  try {
    $uri = [System.Uri]::new($u)
  } catch {
    return $u
  }

  # Convert IDN host (e.g. 한글 도메인) to punycode so Android DNS works reliably.
  try {
    $idn = [System.Globalization.IdnMapping]::new()
    $asciiHost = $idn.GetAscii($uri.DnsSafeHost)
    if ([string]::IsNullOrWhiteSpace($asciiHost)) { return $u }

    $builder = [System.UriBuilder]::new($uri)
    $builder.Host = $asciiHost
    return (Ensure-TrailingSlash $builder.Uri.AbsoluteUri)
  } catch {
    return $u
  }
}

# Default: read from environment first (CI-friendly), otherwise use project default
if ([string]::IsNullOrWhiteSpace($ApiBaseUrl)) {
  $ApiBaseUrl = $env:API_BASE_URL
}

if ([string]::IsNullOrWhiteSpace($ApiBaseUrl)) {
  # Project default (override via -ApiBaseUrl or env var API_BASE_URL)
  # Use punycode by default to avoid terminal/encoding issues.
  $ApiBaseUrl = "https://api.xn--zb0bu7iuubp7hba523s.kr/api/v1/"
}

$ApiBaseUrl = Ensure-TrailingSlash $ApiBaseUrl
$ApiBaseUrl = Normalize-ApiBaseUrl $ApiBaseUrl

$cmd = @(
  "flutter build appbundle --release",
  "--dart-define=API_BASE_URL=$ApiBaseUrl"
)

if (-not [string]::IsNullOrWhiteSpace($BuildName)) {
  $cmd += "--build-name=$BuildName"
}
if (-not [string]::IsNullOrWhiteSpace($BuildNumber)) {
  $cmd += "--build-number=$BuildNumber"
}

$full = $cmd -join " "
Write-Host "Building AAB with API_BASE_URL=$ApiBaseUrl"
Write-Host $full
Invoke-Expression $full

