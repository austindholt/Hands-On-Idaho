param(
  [switch]$Force
)

$ErrorActionPreference = "Stop"

$repoRoot = Resolve-Path (Join-Path $PSScriptRoot "..")
$inboxDir = Join-Path $repoRoot "photo-inbox"
$outputDir = Join-Path $repoRoot "public\images\projects"
$manifestPath = Join-Path $repoRoot "projects.json"
$supportedExtensions = @(".jpg", ".jpeg", ".png")
$maxWidth = 1600
$maxHeight = 1200
$jpegQuality = 82L

New-Item -ItemType Directory -Force -Path $inboxDir | Out-Null
New-Item -ItemType Directory -Force -Path $outputDir | Out-Null

if (-not (Test-Path $manifestPath)) {
  "[]" | Set-Content -Path $manifestPath -Encoding UTF8
}

$projects = @(Get-Content $manifestPath -Raw | ConvertFrom-Json)
$existingSources = @{}
foreach ($project in $projects) {
  if ($project.sourceFile) {
    $existingSources[$project.sourceFile] = $true
  }
}

$files = @(Get-ChildItem -Path $inboxDir -File | Where-Object { $_.Name -ne ".gitkeep" })
if (-not $files.Count) {
  Write-Host "No photos found in photo-inbox. Drop approved JPG or PNG files there, then run this command again."
  exit 0
}

Add-Type -AssemblyName System.Drawing

function Convert-ToSlug {
  param([string]$Value)
  $slug = $Value.ToLowerInvariant()
  $slug = [regex]::Replace($slug, "[^a-z0-9]+", "-")
  $slug = $slug.Trim("-")
  if (-not $slug) { return "project-photo" }
  return $slug
}

function Convert-ToTitle {
  param([string]$Value)
  $words = [regex]::Split($Value, "[^a-zA-Z0-9]+") | Where-Object { $_ }
  if (-not $words.Count) { return "Project Photo" }
  return (($words | ForEach-Object {
    if ($_.Length -le 1) { $_.ToUpperInvariant() } else { $_.Substring(0,1).ToUpperInvariant() + $_.Substring(1).ToLowerInvariant() }
  }) -join " ")
}

function Get-ServiceTags {
  param([string]$Name)
  $lower = $Name.ToLowerInvariant()
  $tags = New-Object System.Collections.Generic.List[string]
  $service = "Small Home Projects"

  if ($lower -match "tv|television|mount") {
    $service = "TV Mounting"
    $tags.Add("TV Mounting")
  }
  if ($lower -match "soundbar|speaker|audio") {
    $service = "Soundbar Setup"
    $tags.Add("Soundbar Setup")
  }
  if ($lower -match "wire|cord|conceal") {
    $service = "Wire Concealment"
    $tags.Add("Wire Concealment")
  }
  if ($lower -match "theater|media") {
    $service = "Home Theater"
    $tags.Add("Home Theater")
  }
  if ($lower -match "shelf|shelves|console") {
    $tags.Add("Floating Shelves")
  }
  if (-not $tags.Count) {
    $tags.Add("Small Home Projects")
  }
  $tags.Add("Treasure Valley")

  return [pscustomobject]@{
    Service = $service
    Tags = @($tags | Select-Object -Unique)
  }
}

function Get-Area {
  param([string]$Name)
  $lower = $Name.ToLowerInvariant()
  foreach ($area in @("Boise", "Meridian", "Eagle", "Nampa", "Kuna", "Star", "Garden City", "Caldwell")) {
    if ($lower -match [regex]::Escape($area.ToLowerInvariant())) {
      return "$area, ID"
    }
  }
  return "Treasure Valley, ID"
}

function Get-UniqueOutputPath {
  param([string]$BaseName)
  $candidate = Join-Path $outputDir "$BaseName.jpg"
  $index = 2
  while ((Test-Path $candidate) -and -not $Force) {
    $candidate = Join-Path $outputDir "$BaseName-$index.jpg"
    $index += 1
  }
  return $candidate
}

function Save-OptimizedJpeg {
  param(
    [string]$InputPath,
    [string]$OutputPath
  )

  $source = [System.Drawing.Image]::FromFile($InputPath)
  try {
    $ratio = [Math]::Min($maxWidth / $source.Width, $maxHeight / $source.Height)
    if ($ratio -gt 1) { $ratio = 1 }
    $width = [Math]::Max(1, [int]($source.Width * $ratio))
    $height = [Math]::Max(1, [int]($source.Height * $ratio))

    $bitmap = New-Object System.Drawing.Bitmap($width, $height)
    try {
      $graphics = [System.Drawing.Graphics]::FromImage($bitmap)
      try {
        $graphics.CompositingQuality = [System.Drawing.Drawing2D.CompositingQuality]::HighQuality
        $graphics.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
        $graphics.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::HighQuality
        $graphics.DrawImage($source, 0, 0, $width, $height)
      } finally {
        $graphics.Dispose()
      }

      $codec = [System.Drawing.Imaging.ImageCodecInfo]::GetImageEncoders() | Where-Object { $_.MimeType -eq "image/jpeg" }
      $encoder = [System.Drawing.Imaging.Encoder]::Quality
      $parameters = New-Object System.Drawing.Imaging.EncoderParameters(1)
      $parameters.Param[0] = New-Object System.Drawing.Imaging.EncoderParameter($encoder, $jpegQuality)
      $bitmap.Save($OutputPath, $codec, $parameters)
    } finally {
      if ($bitmap) { $bitmap.Dispose() }
    }
  } finally {
    $source.Dispose()
  }
}

$added = New-Object System.Collections.Generic.List[object]

foreach ($file in $files) {
  $extension = $file.Extension.ToLowerInvariant()
  if ($supportedExtensions -notcontains $extension) {
    Write-Host "Skipping unsupported file: $($file.Name)"
    continue
  }
  if ($existingSources.ContainsKey($file.Name) -and -not $Force) {
    Write-Host "Skipping already imported file: $($file.Name)"
    continue
  }

  $datePrefix = $file.LastWriteTime.ToString("yyyy-MM-dd")
  $slug = Convert-ToSlug $file.BaseName
  $outputPath = Get-UniqueOutputPath "$datePrefix-$slug"
  Save-OptimizedJpeg -InputPath $file.FullName -OutputPath $outputPath

  $relativeImage = "public/images/projects/$([System.IO.Path]::GetFileName($outputPath))"
  $serviceInfo = Get-ServiceTags $file.BaseName
  $area = Get-Area $file.BaseName
  $title = Convert-ToTitle $file.BaseName

  $added.Add([pscustomobject]@{
    image = $relativeImage
    title = $title
    service = $serviceInfo.Service
    area = $area
    description = "Project photo added from photo-inbox. Review title, description, area, and alt text before publishing if needed."
    alt = "Hands-On Idaho $($serviceInfo.Service.ToLowerInvariant()) project photo in $area"
    tags = $serviceInfo.Tags
    featured = $true
    dateAdded = (Get-Date).ToString("yyyy-MM-dd")
    needsReview = $true
    sourceFile = $file.Name
  })

  Write-Host "Prepared $($file.Name) -> $relativeImage"
}

if ($added.Count) {
  $projects = @($projects) + @($added)
  $projects | ConvertTo-Json -Depth 6 | Set-Content -Path $manifestPath -Encoding UTF8
  Write-Host "Updated projects.json with $($added.Count) new project photo(s)."
  Write-Host "Review entries marked needsReview=true before relying on their titles, descriptions, or alt text."
} else {
  Write-Host "No new supported photos were prepared."
}
