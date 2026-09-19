# ============================================================================
# FILE: diag-lookup_2026-09-19_0052.ps1
# GENERATED: 2026-09-19_0052 UTC (v3 - robust raw-body capture)
# PURPOSE: Show the REAL body of the create-checkout 500 for a piece and a class.
# RUN:     .\supabase\diagnostics\diag-lookup_2026-09-19_0052.ps1
# ============================================================================
$SUPA = "https://tssicoxzxcfijdlvtpqm.supabase.co"
$KEY  = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InRzc2ljb3h6eGNmaWpkbHZ0cHFtIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzM0MzM3NDAsImV4cCI6MjA4OTAwOTc0MH0.g7OlsyUsSv05u7ikmjyt2sOT8aWFGNPwKU65KcATlWU"
$h = @{ apikey = $KEY; Authorization = "Bearer $KEY" }

function Get-Body($err) {
  $b = $null
  if ($err.ErrorDetails -and $err.ErrorDetails.Message) { $b = $err.ErrorDetails.Message }
  if (-not $b -and $err.Exception.Response) {
    try {
      $st = $err.Exception.Response.GetResponseStream()
      $st.Position = 0
      $rd = New-Object System.IO.StreamReader($st)
      $b = $rd.ReadToEnd()
    } catch { }
  }
  if (-not $b) { $b = $err.Exception.Message }
  return $b
}

function Test-Checkout($payload, $label) {
  $body = $payload | ConvertTo-Json
  try {
    $res = Invoke-RestMethod "$SUPA/functions/v1/create-checkout" -Method Post -Headers $h -ContentType "application/json" -Body $body
    Write-Host ("  {0} OK -> {1}" -f $label, $res.url) -ForegroundColor Green
  } catch {
    Write-Host ("  {0} RAW BODY: {1}" -f $label, (Get-Body $_)) -ForegroundColor Red
  }
}

$pieces  = Invoke-RestMethod "$SUPA/rest/v1/pieces?select=id,title,price"  -Headers $h
$classes = Invoke-RestMethod "$SUPA/rest/v1/classes?select=id,title,price" -Headers $h
Write-Host "pieces in DB:" $pieces.Count "  classes in DB:" $classes.Count -ForegroundColor Cyan

$p = $pieces | Where-Object { $_.price } | Select-Object -First 1
Write-Host ""
Write-Host "PIECE id:" $p.id " title:" $p.title
Test-Checkout @{ piece_id = $p.id } "PIECE"

$c = $classes | Where-Object { $_.price } | Select-Object -First 1
Write-Host ""
if ($c) {
  Write-Host "CLASS id:" $c.id " title:" $c.title
  Test-Checkout @{ class_id = $c.id; student_name = "Test"; student_email = "test@example.com" } "CLASS"
} else {
  Write-Host "No priced class in DB." -ForegroundColor Yellow
}
