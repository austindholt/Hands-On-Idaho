# Project Photo Workflow

Optimized website-ready Hands-On Idaho project photos are created here by `scripts/prepare-photos.ps1`.

Recommended naming:
- `tv-mount-boise-living-room.webp`
- `soundbar-mount-meridian-family-room.webp`
- `wire-concealment-treasure-valley.webp`
- `floating-shelf-media-console-eagle.webp`
- `home-theater-setup-boise.webp`

Use only real project photos you have permission to publish. Do not use stock photos or scraped social media images.

Preferred workflow:
1. Drop approved raw JPG, PNG, HEIC, or HEIF photos into `photo-inbox/`.
2. Run `powershell -ExecutionPolicy Bypass -File scripts/prepare-photos.ps1`.
3. Review the generated `projects.json` entries.

Use honest alt text that describes the actual photo, such as "Wall mounted TV installation in Meridian Idaho living room".
