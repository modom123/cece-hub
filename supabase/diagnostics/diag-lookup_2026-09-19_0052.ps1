# ============================================================================
# FILE: diag-lookup_2026-09-19_0052.ps1
# GENERATED: 2026-09-19_0052 UTC
# PURPOSE: Figure out why create-checkout says "Piece not found". Prints the
#          piece id being tested, confirms it round-trips by id, and also tests
#          a CLASS (known fixed id) to tell data-issue vs wrong-project/key.
# RUN:     .\supabase\diagnostics\diag-lookup_2026-09-19_0052.ps1
# ============================================================================
$SUPA = "https://tssicoxzxcfijdlvtpqm.supabase.co"
$KEY  = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InRzc2ljb3h6eGNmaWpkbHZ0cHFtIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzM0MzM3NDAsImV4cCI6MjA4OTAwOTc0MH0.g7OlsyUsSv05u7ikmjyt2sOT8aWFGNPwKU65KcATlWU"
$h = @{ apikey = $KEY; Authorization = "Bearer $KEY" }

function Show-Err($e) {
  $m=$null
  if ($e.ErrorDetails -and $e.ErrorDetails.Message) { $m=$e.ErrorDetails.Message }
  if (-not $m -and $e.Exception.Response) { try { $s=$e.Exception.Response.GetResponseStream(); $s.Position=0; $m=(New-Object System.IO.StreamReader($s)).ReadToEnd() } catch {} }
  if (-not $m) { $m=$e.Exception.Message }
  return $m
}

Write-Host "`n--- pieces the function's project should have ---" -ForegroundColor Cyan
$pieces = Invoke-RestMethod "$SUPA/rest/v1/pieces?select=id,title,price" -Headers $h
$classes = Invoke-RestMethod "$SUPA/rest/v1/classes?select=id,title,price,active" -Headers $h
Write-Host ("pieces: {0}   classes: {1}" -f $pieces.Count, $classes.Count)

$p = $pieces | Where-Object { $_.price } | Select-Object -First 1
Write-Host ("`nTesting PIECE id = '{0}'  title = '{1}'" -f $p.id, $p.title) -ForegroundColor Cyan
$rt = Invoke-RestMethod "$SUPA/rest/v1/pieces?id=eq.$([uri]::EscapeDataString([string]$p.id))&select=id,title" -Headers $h
Write-Host ("  round-trip lookup by that id returned: {0} row(s)" -f $rt.Count)
try {
  $r1 = Invoke-RestMethod "$SUPA/functions/v1/create-checkout" -Method Post -Headers $h -ContentType "application/json" -Body (@{ piece_id = $p.id } | ConvertTo-Json)
  Write-Host ("  PIECE CHECKOUT OK -> {0}" -f $r1.url) -ForegroundColor Green
} catch { Write-Host ("  PIECE CHECKOUT ERROR: " + (Show-Err $_)) -ForegroundColor Red }

if ($classes.Count -gt 0) {
  $c = $classes | Where-Object { $_.price } | Select-Object -First 1
  Write-Host ("`nTesting CLASS id = '{0}'  title = '{1}'" -f $c.id, $c.title) -ForegroundColor Cyan
  try {
    $r2 = Invoke-RestMethod "$SUPA/functions/v1/create-checkout" -Method Post -Headers $h -ContentType "application/json" -Body (@{ class_id = $c.id; student_name = "Test"; student_email = "test@example.com" } | ConvertTo-Json)
    Write-Host ("  CLASS CHECKOUT OK -> {0}" -f $r2.url) -ForegroundColor Green
  } catch { Write-Host ("  CLASS CHECKOUT ERROR: " + (Show-Err $_)) -ForegroundColor Red }
} else {
  Write-Host "`n(No classes in DB yet — run seed_classes_2026-09-19_0052.sql to enable class checkout.)" -ForegroundColor Yellow
}
