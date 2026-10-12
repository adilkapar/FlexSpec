# SheetJS Library (xlsx.full.min.js)

## You need to download this file manually:

### Option 1: Download from CDN (Recommended)
Open this URL in your browser and save the file as `xlsx.full.min.js` in this folder:

https://cdn.sheetjs.com/xlsx-0.20.3/package/dist/xlsx.full.min.js

### Option 2: Using terminal in BAS
Run this command from the webapp/lib/ directory:

```bash
curl -o xlsx.full.min.js https://cdn.sheetjs.com/xlsx-0.20.3/package/dist/xlsx.full.min.js
```

### Option 3: npm (alternative)
```bash
npm install xlsx
```
Then copy `node_modules/xlsx/dist/xlsx.full.min.js` to this folder.

---

## After downloading, add this script tag to webapp/index.html:

Add this line BEFORE the UI5 bootstrap script:

```html
<script src="lib/xlsx.full.min.js"></script>
```

This makes the `XLSX` global object available to the UploadExtension.js controller.