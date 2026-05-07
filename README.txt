# Hands-On Idaho — GitHub Pages Rebuild

This is a static GitHub Pages rebuild for Hands-On Idaho.

## Files in this package
- `index.html`
- `services.html`
- `portfolio.html`
- `contact.html`
- `thank-you.html`
- `404.html`
- `styles.css`
- `script.js`
- `robots.txt`
- `sitemap.xml`
- `CNAME`

## Important
Do not delete your existing image assets unless you are replacing them:
- `logo.png`
- `favicon.ico`
- `og-image.png`
- `project1.JPG`
- `project2.JPG`
- `project3.jpeg`

This rebuild references those existing files.

## Preserved from your current site
- Domain: `handsonidaho.com`
- Phone: (208) 861-2302
- Email: handsonidaho@outlook.com
- Instagram, Facebook, Nextdoor, and Google Business Profile links
- Google Analytics ID: G-B5PNK5EFXL
- Formspree contact form endpoint: https://formspree.io/f/mzzaloqw

## Static-site checks
- GitHub Pages should deploy from the `main` branch root so `index.html`, `CNAME`, `robots.txt`, and `sitemap.xml` are served at the domain root.
- The contact form posts directly to Formspree from `contact.html`; `script.js` only updates the submit button/status text and does not block the native form submit.
- Confirm the Formspree endpoint is configured to notify `handsonidaho@outlook.com` and, if desired, redirect successful submissions to `https://handsonidaho.com/thank-you.html`.

## Deploy through GitHub
1. Go to your repo: `austindholt/Hands-On-Idaho`
2. Upload/replace the files from this folder.
3. Keep existing image files in the repo.
4. Commit changes to `main`.
5. Wait a minute or two for GitHub Pages to update.
6. Visit https://handsonidaho.com

## Easy edit spots
- Phone/email/social links are repeated in the HTML files.
- Colors and layout are in `styles.css`.
- Form behavior and mobile menu are in `script.js`.
- Project photos are controlled in `portfolio.html`.
