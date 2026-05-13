param(
  [switch]$Force
)

$ErrorActionPreference = "Stop"

$repoRoot = Resolve-Path (Join-Path $PSScriptRoot "..")
$inboxDir = Join-Path $repoRoot "photo-inbox"
$outputDir = Join-Path $repoRoot "public\images\projects"
$manifestPath = Join-Path $repoRoot "projects.json"
$supportedExtensions = @(".jpg", ".jpeg", ".png", ".heic", ".heif")
$maxWidth = 1600
$maxHeight = 1200
$jpegQuality = 82L

New-Item -ItemType Directory -Force -Path $inboxDir | Out-Null
New-Item -ItemType Directory -Force -Path $outputDir | Out-Null

if (-not (Test-Path $manifestPath)) {
  "[]" | Set-Content -Path $manifestPath -Encoding UTF8
}

$loadedProjects = Get-Content $manifestPath -Raw | ConvertFrom-Json
$projects = New-Object System.Collections.Generic.List[object]
foreach ($project in @($loadedProjects)) {
  if ($project.PSObject.Properties.Name -contains "image") {
    $projects.Add($project)
  } elseif ($project.PSObject.Properties.Name -contains "value") {
    foreach ($nestedProject in @($project.value)) {
      if ($nestedProject.PSObject.Properties.Name -contains "image") {
        $projects.Add($nestedProject)
      }
    }
  }
}
$existingSources = @{}
foreach ($project in $projects) {
  if ($project.sourceFile) {
    $existingSources[$project.sourceFile] = $true
  }
  if ($project.sourceFiles) {
    foreach ($sourceFile in @($project.sourceFiles)) {
      $existingSources[$sourceFile] = $true
    }
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
    if ($source.PropertyIdList -contains 274) {
      $orientation = $source.GetPropertyItem(274).Value[0]
      switch ($orientation) {
        3 { $source.RotateFlip([System.Drawing.RotateFlipType]::Rotate180FlipNone) }
        6 { $source.RotateFlip([System.Drawing.RotateFlipType]::Rotate90FlipNone) }
        8 { $source.RotateFlip([System.Drawing.RotateFlipType]::Rotate270FlipNone) }
      }
    }

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

function Save-HeicOptimizedJpegWithImageMagick {
  param(
    [string]$InputPath,
    [string]$OutputPath
  )

  $magick = Get-Command magick -ErrorAction SilentlyContinue
  $magickPath = $null
  if ($magick) {
    $magickPath = $magick.Source
  } else {
    $standardInstall = Get-ChildItem -Path "$env:ProgramFiles\ImageMagick-*" -Filter magick.exe -Recurse -ErrorAction SilentlyContinue | Select-Object -First 1
    if ($standardInstall) {
      $magickPath = $standardInstall.FullName
    }
  }

  if (-not $magickPath) {
    return $false
  }

  & $magickPath $InputPath -auto-orient -resize "$($maxWidth)x$($maxHeight)>" -strip -quality $jpegQuality $OutputPath
  if ($LASTEXITCODE -ne 0) {
    throw "ImageMagick failed to convert $InputPath"
  }

  return $true
}

function Save-HeicOptimizedJpegWithWindowsCodec {
  param(
    [string]$InputPath,
    [string]$OutputPath
  )

  Add-Type -AssemblyName PresentationCore
  Add-Type -AssemblyName WindowsBase

  $stream = [System.IO.File]::OpenRead($InputPath)
  try {
    $decoder = [System.Windows.Media.Imaging.BitmapDecoder]::Create(
      $stream,
      [System.Windows.Media.Imaging.BitmapCreateOptions]::PreservePixelFormat,
      [System.Windows.Media.Imaging.BitmapCacheOption]::OnLoad
    )
    $frame = $decoder.Frames[0]

    $ratio = [Math]::Min($maxWidth / $frame.PixelWidth, $maxHeight / $frame.PixelHeight)
    if ($ratio -gt 1) { $ratio = 1 }

    $source = $frame
    if ($ratio -lt 1) {
      $source = New-Object System.Windows.Media.Imaging.TransformedBitmap(
        $frame,
        (New-Object System.Windows.Media.ScaleTransform($ratio, $ratio))
      )
    }

    $encoder = New-Object System.Windows.Media.Imaging.JpegBitmapEncoder
    $encoder.QualityLevel = [int]$jpegQuality
    $encoder.Frames.Add([System.Windows.Media.Imaging.BitmapFrame]::Create($source))

    $outStream = [System.IO.File]::Create($OutputPath)
    try {
      $encoder.Save($outStream)
    } finally {
      $outStream.Dispose()
    }
  } finally {
    $stream.Dispose()
  }
}

function Save-WebsiteJpeg {
  param(
    [System.IO.FileInfo]$File,
    [string]$OutputPath
  )

  $extension = $File.Extension.ToLowerInvariant()
  if ($extension -in @(".heic", ".heif")) {
    if (Save-HeicOptimizedJpegWithImageMagick -InputPath $File.FullName -OutputPath $OutputPath) {
      return
    }

    try {
      Save-HeicOptimizedJpegWithWindowsCodec -InputPath $File.FullName -OutputPath $OutputPath
      return
    } catch {
      throw "Could not decode $($File.Name). Install ImageMagick or the Microsoft HEIF Image Extensions, or export this photo from iPhone/iCloud as JPEG."
    }
  }

  Save-OptimizedJpeg -InputPath $File.FullName -OutputPath $OutputPath
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
  try {
    Save-WebsiteJpeg -File $file -OutputPath $outputPath
  } catch {
    if (Test-Path $outputPath) {
      Remove-Item -LiteralPath $outputPath -Force
    }
    Write-Host $_
    continue
  }

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
  foreach ($project in $added.ToArray()) {
    $projects.Add($project)
  }
  $projects.ToArray() | ConvertTo-Json -Depth 6 | Set-Content -Path $manifestPath -Encoding UTF8
  Write-Host "Updated projects.json with $($added.Count) new project photo(s)."
  Write-Host "Review entries marked needsReview=true before relying on their titles, descriptions, or alt text."
} else {
  Write-Host "No new supported photos were prepared."
}
