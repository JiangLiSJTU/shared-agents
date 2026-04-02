# render_mermaid.ps1 — Reusable Mermaid batch renderer (SVG/PNG/PDF)
# Part of skill: mermaid-svg-renderer
#
# Usage:
#   powershell -ExecutionPolicy Bypass -File render_mermaid.ps1 `
#       -MdFile ".\my_slides.md" `
#       -OutDir ".\svg_output" `
#       -Format "svg" `
#       -Width 2400 `
#       -Background transparent
#
# Parameters:
#   -MdFile      Path to the Markdown file containing ```mermaid blocks
#   -OutDir      Output directory for images (created if absent)
#   -Format      Output format: svg, png, or pdf (default: svg)
#   -Width       Render width in pixels (for PNG, 4800 is recommended for high-res)
#   -Background  Background color passed to mmdc -b flag (default: transparent)
#   -Labels      Optional: comma-separated list of base filenames (no extension)
#                If fewer labels than blocks, remaining files are numbered diagram_NN

param(
    [Parameter(Mandatory=$true)]
    [string]$MdFile,

    [string]$OutDir      = ".\mermaid_out",
    [string]$Format      = "svg",
    [int]   $Width       = 2400,
    [string]$Background  = "transparent",
    [string]$Labels      = ""   # comma-separated, optional
)

# ── Preflight: check mmdc ─────────────────────────────────────────────────────
$mmdc_check = & mmdc --version 2>&1
if ($LASTEXITCODE -ne 0) {
    Write-Error "mmdc not found. Install with: npm install -g @mermaid-js/mermaid-cli"
    exit 1
}
Write-Host "[mermaid-svg-renderer] mmdc $mmdc_check"

# ── Resolve paths ─────────────────────────────────────────────────────────────
$MdFile = Resolve-Path $MdFile
New-Item -ItemType Directory -Force -Path $OutDir | Out-Null
$OutDir = Resolve-Path $OutDir

# ── Extract mermaid blocks ────────────────────────────────────────────────────
$content = [System.IO.File]::ReadAllText($MdFile, [System.Text.Encoding]::UTF8)
$pattern = '(?s)```mermaid\r?\n(.*?)\r?\n```'
$found   = [regex]::Matches($content, $pattern)
$total   = $found.Count

if ($total -eq 0) {
    Write-Warning "No mermaid blocks found in: $MdFile"
    exit 0
}
Write-Host ("[mermaid-svg-renderer] Found {0} block(s) in {1}" -f $total, (Split-Path $MdFile -Leaf))

# ── Build label list ──────────────────────────────────────────────────────────
$labelArr = @()
if ($Labels -ne "") {
    $labelArr = $Labels -split ',' | ForEach-Object { $_.Trim() }
}

# ── Render loop ───────────────────────────────────────────────────────────────
$ok   = 0
$fail = 0

for ($i = 0; $i -lt $total; $i++) {
    # Determine output filename
    if ($i -lt $labelArr.Count -and $labelArr[$i] -ne "") {
        $label = $labelArr[$i]
    } else {
        $label = "diagram_" + $i.ToString("D2")
    }

    $mmdFile = Join-Path $OutDir ($label + ".mmd")
    $outFile = Join-Path $OutDir ($label + "." + $Format)

    # Write temp .mmd
    $code = $found[$i].Groups[1].Value
    [System.IO.File]::WriteAllText($mmdFile, $code, [System.Text.Encoding]::UTF8)

    $prefix = "[{0:D2}/{1}] {2}" -f ($i+1), $total, $label
    Write-Host "$prefix ..." -NoNewline

    # Call mmdc
    $result   = & mmdc -i $mmdFile -o $outFile -b $Background -w $Width 2>&1
    $exitCode = $LASTEXITCODE

    if ($exitCode -eq 0 -and (Test-Path $outFile)) {
        $sizeKB = [math]::Round((Get-Item $outFile).Length / 1024, 1)
        Write-Host (" OK ({0} KB)" -f $sizeKB)
        $ok++
    } else {
        Write-Host " FAILED"
        Write-Host ("  " + ($result -join "`n  "))
        $fail++
    }

    Remove-Item $mmdFile -ErrorAction SilentlyContinue
}

# ── Summary ───────────────────────────────────────────────────────────────────
Write-Host ("="*60)
Write-Host ("[mermaid-svg-renderer] Done: {0} OK / {1} FAILED" -f $ok, $fail)
Write-Host ("[mermaid-svg-renderer] Output -> {0}" -f $OutDir)

if ($fail -gt 0) { exit 1 } else { exit 0 }
