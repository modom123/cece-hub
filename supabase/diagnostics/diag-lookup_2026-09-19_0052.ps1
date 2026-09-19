# ============================================================================
# FILE: diag-lookup_2026-09-19_0052.ps1
# GENERATED: 2026-09-19_0052 UTC (rewritten simple for Windows PowerShell 5.1)
# PURPOSE: Why does create-checkout say "Piece not found"? Tests a piece AND a
#          class (known id). Class OK + piece fail = data issue; both fail =
#          function env (SUPABASE_URL / service role) issue.
# RUN:     .\supabase\diagnostics\diag-lookup_2026-09-19_0052.ps1
# ============================================================================
$SUPA = "https://tssicoxzxcfijdlvtpqm.supabase.co"
$KEY  = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InRzc2ljb3h6eGNmaWpkbHZ0cHFtIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzM0MzM3NDAsImV4cCI6MjA4OTAwOTc0MH0.g7OlsyUsSv05u7ikmjyt2sOT8aWFGNPwKU65KcATlWU"
$h = @{ apikey = $KEY; Authorization = "Bearer $KEY" }

$pieces  = Invoke-RestMethod "$SUPA/rest/v1/pieces?select=id,title,price"  -Headers $h
$classes = Invoke-RestMethod "$SUPA/rest/v1/classes?select=id,title,price" -Headers $h
Write-Host "pieces in DB:" $pieces.Count "  classes in DB:" $classes.Count -ForegroundColor Cyan

$p = $pieces | Where-Object { $_.price } | Select-Object -First 1
Write-Host ""
Write-Host "Testing PIECE  id:" $p.id "  title:" $p.title
$pbody = @{ piece_id = $p.id } | ConvertTo-Json
try {
  $r1 = Invoke-RestMethod "$SUPA/functions/v1/create-checkout" -Method Post -Headers $h -ContentType "application/json" -Body $pbody
  Write-Host "  PIECE CHECKOUT OK ->" $r1.url -ForegroundColor Green
} catch {
  $m = $_.ErrorDetails.Message
  if (-not $m) { $m = $_.Exception.Message }
  Write-Host "  PIECE CHECKOUT ERR:" $m -ForegroundColor Red
}

$c = $classes | Where-Object { $_.price } | Select-Object -First 1
Write-Host ""
if ($c) {
  Write-Host "Testing CLASS  id:" $c.id "  title:" $c.title
  $cbody = @{ class_id = $c.id; student_name = "Test"; student_email = "test@example.com" } | ConvertTo-Json
  try {
    $r2 = Invoke-RestMethod "$SUPA/functions/v1/create-checkout" -Method Post -Headers $h -ContentType "application/json" -Body $cbody
    Write-Host "  CLASS CHECKOUT OK ->" $r2.url -ForegroundColor Green
  } catch {
    $m = $_.ErrorDetails.Message
    if (-not $m) { $m = $_.Exception.Message }
    Write-Host "  CLASS CHECKOUT ERR:" $m -ForegroundColor Red
  }
} else {
  Write-Host "No priced class in DB (run seed_classes SQL to enable class checkout)." -ForegroundColor Yellow
}
