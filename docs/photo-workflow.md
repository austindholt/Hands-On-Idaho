# Project Photo Workflow

This site uses real local project photos only. Do not scrape photos from Instagram, Facebook, Nextdoor, Google, iCloud, a phone, or a NAS. Pick approved photos manually, then drop copies into the repo.

## Folders

- `photo-inbox/` is where you drop approved raw JPG or PNG photos. Git ignores the files in this folder.
- `public/images/projects/` is where optimized website-ready photos are created.
- `projects.json` is the project photo manifest used by the website gallery and homepage featured rotation.

## Prepare New Photos

1. Copy approved photos into `photo-inbox/`.
2. Run:

```powershell
powershell -ExecutionPolicy Bypass -File scripts/prepare-photos.ps1
```

If you have npm installed, this also works:

```powershell
npm run photos:prepare
```

The script scans `photo-inbox/`, ignores unsupported files, resizes JPG/PNG/HEIC/HEIF images to a website-friendly size, saves optimized JPEG files in `public/images/projects/`, strips metadata by redrawing or re-encoding the image, avoids overwriting existing processed photos, and appends new entries to `projects.json`.

HEIC/HEIF support uses ImageMagick if `magick` is installed. If ImageMagick is not installed, it tries the Windows HEIF codec. If neither is available, export the iPhone photo as JPEG or install one of those decoders.

## Manual Review

New manifest entries are marked with `"needsReview": true`. Review and update:

- `title`
- `service`
- `area`
- `description`
- `alt`
- `tags`
- `featured`

Good alt text examples:

- `Wall mounted TV installation in Meridian Idaho living room`
- `Soundbar and TV mounting setup for Boise homeowner`
- `Clean TV wire concealment project in the Treasure Valley`
- `Home theater setup with mounted TV and media console`

## Featured Rotation

The full portfolio gallery reads all visible entries in `projects.json`. The homepage reads the same manifest, filters to entries where `featured` is not `false`, and shows a deterministic weekly set. It uses the current week number, so the homepage changes over time without reshuffling on every refresh.

Set `"featured": false` on any photo that should stay in the full gallery but not rotate onto the homepage.

Set `"hidden": true` on any photo that should not be shown publicly.

## Group Similar Photos

If multiple photos belong to the same job, keep them under one project entry with an `images` array instead of creating one card per photo. The first image is used as the main card image and the remaining images show as thumbnails.

Example:

```json
{
  "title": "Frame TV and Soundbar Setup",
  "service": "TV Mounting",
  "area": "Treasure Valley, ID",
  "description": "Before, in-progress, and finished photos from a residential Frame TV mounting project.",
  "tags": ["TV Mounting", "Soundbar Setup", "Before & After"],
  "featured": true,
  "needsReview": true,
  "images": [
    {
      "image": "public/images/projects/frame-tv-mount-before-treasure-valley.jpg",
      "alt": "Before photo showing wall mount placement for a Frame TV setup"
    },
    {
      "image": "public/images/projects/frame-tv-soundbar-finished-treasure-valley.jpg",
      "alt": "Finished Frame TV and soundbar mounting setup"
    }
  ],
  "sourceFiles": ["IMG_7172-1.heic", "IMG_7178-1.heic"]
}
```

## Photo Categories

Use residential homeowner-friendly tags such as:

- `TV Mounting`
- `Soundbar Setup`
- `Wire Concealment`
- `Home Theater`
- `Media Wall`
- `Floating Shelves`
- `Small Home Projects`
- `Before & After`

## Photos To Avoid

Do not publish photos that show customer addresses, license plates, faces without permission, personal documents, private sensitive rooms, security/access control equipment, commercial low-voltage work, surveillance systems, network racks, data drops, or anything that creates a non-compete concern.

## Notes

The script uses local Windows/PowerShell image tools and optional local ImageMagick support. It does not require private credentials or external accounts. It creates optimized JPEG files rather than WebP because the current repo has no Node/npm image tooling installed.
