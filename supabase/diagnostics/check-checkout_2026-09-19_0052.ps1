# ============================================================================
# FILE: check-checkout_2026-09-19_0052.ps1
# GENERATED: 2026-09-19_0052 UTC
# PURPOSE: One-shot check of the cecespieces public checkout path. Verifies the
#          public (anon) key can read pieces, then asks create-checkout for a
#          Stripe session and prints the exact result. No copy-paste of keys.
# RUN:     powershell -ExecutionPolicy Bypass -File .\supabase\diagnostics\check-checkout_2026-09-19_0052.ps1
# ============================================================================

$SUPA = "https://tssicoxzxcfijdlvtpqm.supabase.co"
$KEY  = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InRzc2ljb3h6eGNmaWpkbHZ0cHFtIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzM0MzM3NDAsImV4cCI6MjA4OTAwOTc0MH0.g7OlsyUsSv05u7ikmjyt2sOT8aWFGNPwKU65KcATlWU"
$h = @{ apikey = $KEY; Authorization = "Bearer $KEY" }

Write-Host "`n[1/2] Can the PUBLIC site read pieces?" -ForegroundColor Cyan
try {
  $pieces = Invoke-RestMethod "$SUPA/rest/v1/pieces?select=id,title,price" -Headers $h
} catch {
  Write-Host "  READ FAILED:" -ForegroundColor Red
  if ($_.ErrorDetails.Message) { Write-Host ("  " + $_.ErrorDetails.Message) -ForegroundColor Red }
  else { Write-Host ("  " + $_.Exception.Message) -ForegroundColor Red }
  Write-Host "`n  If this says 'Invalid API key', your project's LEGACY anon key is turned off." -ForegroundColor Yellow
  Write-Host "  Fix in Supabase Dashboard -> Settings -> API Keys (enable legacy keys), then re-run." -ForegroundColor Yellow
  exit 1
}
Write-Host ("  Pieces readable: {0}" -f $pieces.Count) -ForegroundColor Green
$p = $pieces | Where-Object { $_.price } | Select-Object -First 1
if (-not $p) { Write-Host "  No piece has a price set." -ForegroundColor Yellow; exit 1 }

Write-Host ("`n[2/2] Asking create-checkout for a Stripe session ({0})..." -f $p.title) -ForegroundColor Cyan
$body = @{ piece_id = $p.id } | ConvertTo-Json
try {
  $res = Invoke-RestMethod "$SUPA/functions/v1/create-checkout" -Method Post -Headers $h -ContentType "application/json" -Body $body
  Write-Host ("  CHECKOUT OK -> {0}" -f $res.url) -ForegroundColor Green
  Write-Host "`n  SUCCESS. Hard-refresh the website (Ctrl+Shift+R) and Buy Now will go to Stripe." -ForegroundColor Green
} catch {
  Write-Host "  CHECKOUT ERROR (raw response body):" -ForegroundColor Red
  $msg = $null
  if ($_.ErrorDetails -and $_.ErrorDetails.Message) { $msg = $_.ErrorDetails.Message }
  if (-not $msg -and $_.Exception.Response) {
    try {
      $stream = $_.Exception.Response.GetResponseStream()
      $stream.Position = 0
      $reader = New-Object System.IO.StreamReader($stream)
      $msg = $reader.ReadToEnd()
    } catch { }
  }
  if (-not $msg) { $msg = $_.Exception.Message }
  Write-Host ("  " + $msg) -ForegroundColor Red
  Write-Host "`n  Reading the message above:" -ForegroundColor Yellow
  Write-Host "   - 'Invalid API Key'         -> STRIPE_SECRET_KEY is wrong/placeholder; set the real sk_live_ / rk_live_ and re-run." -ForegroundColor Yellow
  Write-Host "   - '...does not have access'  -> your restricted key lacks 'Checkout Sessions: Write'; fix its permissions in Stripe." -ForegroundColor Yellow
  Write-Host "   - 'No such...' / other       -> paste it to Claude." -ForegroundColor Yellow
}
