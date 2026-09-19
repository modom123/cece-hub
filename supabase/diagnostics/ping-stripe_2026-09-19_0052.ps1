# ============================================================================
# FILE: ping-stripe_2026-09-19_0052.ps1
# GENERATED: 2026-09-19_0052 UTC
# PURPOSE: Ask the deployed function to test its OWN outbound network: a raw
#          fetch to Stripe's API (bypassing the SDK) and to the public internet.
# RUN:     .\supabase\diagnostics\ping-stripe_2026-09-19_0052.ps1
# ============================================================================
$SUPA = "https://tssicoxzxcfijdlvtpqm.supabase.co"
$KEY  = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InRzc2ljb3h6eGNmaWpkbHZ0cHFtIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzM0MzM3NDAsImV4cCI6MjA4OTAwOTc0MH0.g7OlsyUsSv05u7ikmjyt2sOT8aWFGNPwKU65KcATlWU"
$h = @{ apikey = $KEY; Authorization = "Bearer $KEY" }
try {
  $r = Invoke-RestMethod "$SUPA/functions/v1/create-checkout" -Method Post -Headers $h -ContentType "application/json" -Body '{"_ping":true}'
  Write-Host "PROBE RESULT:" -ForegroundColor Cyan
  $r | ConvertTo-Json
} catch {
  $m = $_.ErrorDetails.Message
  if (-not $m -and $_.Exception.Response) { try { $s=$_.Exception.Response.GetResponseStream(); $s.Position=0; $m=(New-Object System.IO.StreamReader($s)).ReadToEnd() } catch {} }
  if (-not $m) { $m = $_.Exception.Message }
  Write-Host ("PROBE ERROR: " + $m) -ForegroundColor Red
}
