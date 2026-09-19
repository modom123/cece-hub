# ============================================================================
# FILE: redeploy-and-test_2026-09-19_0052.ps1
# GENERATED: 2026-09-19_0052 UTC
# PURPOSE: Redeploy create-checkout WITH the fetch-HTTP-client fix, then test it
#          in one shot, so the deploy can't be skipped. Run from the cece-hub
#          repo root after `git pull origin main`.
# RUN:     .\supabase\diagnostics\redeploy-and-test_2026-09-19_0052.ps1
# ============================================================================

Write-Host "`n=== Commit currently checked out ===" -ForegroundColor Cyan
git log --oneline -1

Write-Host "`n=== Is the fetch-client fix in the file? (must print a match) ===" -ForegroundColor Cyan
Select-String -Path .\supabase\functions\create-checkout\index.ts -Pattern "createFetchHttpClient"

Write-Host "`n=== Deploying create-checkout (public) ===" -ForegroundColor Cyan
supabase functions deploy create-checkout --no-verify-jwt

Write-Host "`n=== Waiting 8s for the new version to go live ===" -ForegroundColor Cyan
Start-Sleep -Seconds 8

Write-Host "`n=== Testing checkout ===" -ForegroundColor Cyan
$SUPA = "https://tssicoxzxcfijdlvtpqm.supabase.co"
$KEY  = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InRzc2ljb3h6eGNmaWpkbHZ0cHFtIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzM0MzM3NDAsImV4cCI6MjA4OTAwOTc0MH0.g7OlsyUsSv05u7ikmjyt2sOT8aWFGNPwKU65KcATlWU"
$h = @{ apikey = $KEY; Authorization = "Bearer $KEY" }
$p = (Invoke-RestMethod "$SUPA/rest/v1/pieces?select=id,title,price" -Headers $h | Where-Object { $_.price } | Select-Object -First 1)
$body = @{ piece_id = $p.id } | ConvertTo-Json
try {
  $res = Invoke-RestMethod "$SUPA/functions/v1/create-checkout" -Method Post -Headers $h -ContentType "application/json" -Body $body
  Write-Host ("CHECKOUT OK -> {0}" -f $res.url) -ForegroundColor Green
  Write-Host "SUCCESS! Hard-refresh your site (Ctrl+Shift+R) and Buy Now goes to Stripe." -ForegroundColor Green
} catch {
  $msg = $null
  if ($_.ErrorDetails -and $_.ErrorDetails.Message) { $msg = $_.ErrorDetails.Message }
  if (-not $msg -and $_.Exception.Response) { try { $s=$_.Exception.Response.GetResponseStream(); $s.Position=0; $msg=(New-Object System.IO.StreamReader($s)).ReadToEnd() } catch {} }
  if (-not $msg) { $msg = $_.Exception.Message }
  Write-Host ("CHECKOUT ERROR: " + $msg) -ForegroundColor Red
}
