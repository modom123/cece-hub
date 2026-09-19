# ============================================================================
# FILE: redeploy-and-test_2026-09-19_0052.ps1
# GENERATED: 2026-09-19_0052 UTC (v2 - correct single-id extraction)
# PURPOSE: Deploy create-checkout with the current fixes, then test a real
#          piece AND class in one shot. This is the whole finish line.
# RUN:     .\supabase\diagnostics\redeploy-and-test_2026-09-19_0052.ps1
# ============================================================================

Write-Host "`n=== Deploying create-checkout (public) ===" -ForegroundColor Cyan
supabase functions deploy create-checkout --no-verify-jwt

Write-Host "`n=== Waiting 8s for the new version to go live ===" -ForegroundColor Cyan
Start-Sleep -Seconds 8

$SUPA = "https://tssicoxzxcfijdlvtpqm.supabase.co"
$KEY  = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InRzc2ljb3h6eGNmaWpkbHZ0cHFtIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzM0MzM3NDAsImV4cCI6MjA4OTAwOTc0MH0.g7OlsyUsSv05u7ikmjyt2sOT8aWFGNPwKU65KcATlWU"
$h = @{ apikey = $KEY; Authorization = "Bearer $KEY" }

function Get-Body($err) {
  $b = $null
  if ($err.ErrorDetails -and $err.ErrorDetails.Message) { $b = $err.ErrorDetails.Message }
  if (-not $b -and $err.Exception.Response) { try { $st=$err.Exception.Response.GetResponseStream(); $st.Position=0; $b=(New-Object System.IO.StreamReader($st)).ReadToEnd() } catch {} }
  if (-not $b) { $b = $err.Exception.Message }
  return $b
}

# --- pick ONE piece id (assign to a var first so the pipeline enumerates) ---
$allPieces = Invoke-RestMethod "$SUPA/rest/v1/pieces?select=id,title,price" -Headers $h
$priced = @($allPieces | Where-Object { $_.price })
$p = $priced[0]
$pieceId = [string]$p.id
Write-Host "`n=== Testing PIECE ===" -ForegroundColor Cyan
Write-Host ("  sending piece_id: {0}  ({1})" -f $pieceId, $p.title)
try {
  $r1 = Invoke-RestMethod "$SUPA/functions/v1/create-checkout" -Method Post -Headers $h -ContentType "application/json" -Body (@{ piece_id = $pieceId } | ConvertTo-Json)
  Write-Host ("  PIECE CHECKOUT OK -> {0}" -f $r1.url) -ForegroundColor Green
} catch { Write-Host ("  PIECE ERROR: " + (Get-Body $_)) -ForegroundColor Red }

# --- pick ONE class id ---
$allClasses = Invoke-RestMethod "$SUPA/rest/v1/classes?select=id,title,price" -Headers $h
$cpriced = @($allClasses | Where-Object { $_.price })
Write-Host "`n=== Testing CLASS ===" -ForegroundColor Cyan
if ($cpriced.Count -gt 0) {
  $c = $cpriced[0]
  $cid = [string]$c.id
  Write-Host ("  sending class_id: {0}  ({1})" -f $cid, $c.title)
  try {
    $r2 = Invoke-RestMethod "$SUPA/functions/v1/create-checkout" -Method Post -Headers $h -ContentType "application/json" -Body (@{ class_id = $cid; student_name = "Test"; student_email = "test@example.com" } | ConvertTo-Json)
    Write-Host ("  CLASS CHECKOUT OK -> {0}" -f $r2.url) -ForegroundColor Green
  } catch { Write-Host ("  CLASS ERROR: " + (Get-Body $_)) -ForegroundColor Red }
} else { Write-Host "  (no priced class)" -ForegroundColor Yellow }

Write-Host "`nIf both say OK, hard-refresh your site (Ctrl+Shift+R) - checkout is live." -ForegroundColor Green
