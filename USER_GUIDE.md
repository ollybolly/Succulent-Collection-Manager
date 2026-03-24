# 📖 User Guide
## 🌵 Cactus & Succulent Collection Tracker

Welcome! This guide covers everything the app can do, written for collectors rather than programmers. If you haven't installed the app yet, start with [INSTALL.md](INSTALL.md) first.

---

## 🌿 What this app lets you do

| I want to… | Where to go |
|---|---|
| 🔍 Find a plant in my collection | **Collection** → search box |
| ➕ Add a new plant | **Add Plant** tab |
| 📏 Record a measurement | **Record Data** → Measurements |
| 🌸 Log a flowering event | **Record Data** → Flowering |
| 🪨 Record or edit a soil mix | **Record Data** → Soil Mix |
| 📷 Upload photos of a plant | **Record Data** → Photos, or via the plant's detail panel |
| 🖼️ Browse all photos by taxonomy | **Gallery** tab |
| 📅 Log a repot, treatment, or other event | **Events & Notes** tab |
| 📈 See how a plant has grown over time | **Growth Charts** tab |
| 🌱 Manage a seed batch | **Seeds & Germination** tab |
| 📷 Attach a photo to a seedling count | **Seeds & Germination** → Log Count / Event |
| 🏷️ Print plant labels | **Tools** → Labels |
| 📤 Export my collection to Excel | **Tools** → Export |
| 📥 Import an existing plant list | **Tools** → Import |
| ✏️ Correct a mistake | Click the plant → **Edit plant**, or select a row → **Edit selected row** |

---

## 🗂️ The layout

The app has a **green sidebar** on the left with eight sections. Click any item to switch to that section.

| Section | Purpose |
|---|---|
| 🪴 **Collection** | Browse and search all plants; view details; edit, archive, or delete |
| ➕ **Add Plant** | Register a new plant in your collection |
| 📝 **Record Data** | Log measurements, flowering events, soil mixes, and photos |
| 📅 **Events & Notes** | Record cultivation events (repotting, treatments, dormancy, etc.) |
| 📈 **Growth Charts** | Visualise growth over time for any plant |
| 🌱 **Seeds & Germination** | Manage seed batches, survival counts, and graduate seedlings |
| 🔧 **Tools** | Print labels, export to Excel, import from a spreadsheet |
| 🖼️ **Gallery** | Browse all plant photos organised by family, genus, and species |

---

## 🪴 Collection

### Browsing your plants

The Collection tab opens with a **Collection Summary** box at the top (collapsed by default) and the plant table below.

- Click **Collection Summary** to expand two bar charts showing your active plants by Family and by Genus, plus a summary line (e.g. "44 active plants across 12 genera in 6 families")
- 🔽 Use the **Status** dropdown to switch between active, archived, deceased, or gifted plants
- 🔍 Type in the **Search** box to filter by genus, species, family, or common name
- 🔼🔽 Click any **column header** to sort; click again to reverse
- 🖼️ The leftmost column shows a small thumbnail of the most recent photo for each plant

### 🔎 Viewing a plant's full details

Click any row in the table. A **detail panel expands below** showing everything recorded for that plant — taxonomy, origin, dormancy, soil mix history, a Llifle link, and photos. Click the same row again to collapse it.

### 📦 Archiving plants

Archiving is the **safe option** for plants you no longer have. All records are kept and the plant can be restored via DB Browser for SQLite.

1. Select a row
2. Click **Archive selected** (🟠 orange button)
3. Confirm in the dialog

### 🗑️ Permanently deleting plants

Use this for bad imports or test entries.

1. Select a row
2. Click **Delete selected** (🔴 red button)
3. Read the warning — **this cannot be undone**
4. Click **Delete permanently**

### ✏️ Editing a plant record

1. Click the plant's row to open its detail panel
2. Click **Edit plant** (🔵 blue button)
3. Change whatever needs updating and click **Save changes**

> ✅ The table returns to your previous page position after saving.

> 💡 **Family auto-fill:** type a genus you've used before and the family field fills automatically. If other plants of the same genus have a different or missing family, the app offers to update them all at once.

### 📷 Photos in the detail panel

The detail panel shows all photos for the selected plant. Each thumbnail has a small **×** button to delete it. Below the thumbnails there is always an **Add photo** section where you can upload one or more new photos directly without leaving the Collection tab.

### 📋 Duplicating a plant

1. Click the plant's row to open the detail panel
2. Click **Duplicate** (grey button)
3. The app switches to Add Plant with all fields pre-filled — change what differs and click **Add Plant**

---

## ➕ Add Plant

Use this to register a new plant. All fields except Genus are optional.

### Fields explained

**🔬 Taxonomy**

| Field | Example |
|---|---|
| Family | `Aizoaceae` · `Cactaceae` |
| Genus *(required)* | `Lithops` · `Echinopsis` |
| Species | `fulviceps` · `pachanoi` |
| Cultivar / form | `'Cole's Yellow'` · `v. aurantiaca` |
| Common name | `Living stone` · `San Pedro` |

**🛒 Acquisition**

| Field | Notes |
|---|---|
| Source | purchase, seed, cutting, offset, gift, or other |
| Supplier / From | Nursery, seed bank, person, or "own collection" |
| Date acquired | When you received the plant |

**🌍 Origin & Ecology**

| Field | Example |
|---|---|
| Geographic origin | `Richtersveld, South Africa` · `Atacama Desert, Chile` |
| Native substrate | `quartzite gravel` · `limestone scree` |
| Dormancy | Summer dormant ☀️ · Winter dormant ❄️ · None |

**📚 Reference & Other**
- *Llifle URL* — paste the species page URL from llifle.com
- *Toxicity* — e.g. `highly toxic to livestock`
- *General notes* — provenance, catalogue number, anything else

**📷 Photo (optional)** — upload one or more photos at the time of adding the plant. These appear immediately in the collection table and Gallery.

---

## 📝 Record Data

Four sub-tabs: **Measurements**, **Flowering**, **Soil Mix**, and **Photos**.

### 📏 Measurements

Record height (mm), width (mm), and offsets/heads/pads at any date. Over time this builds a growth history visible in Growth Charts.

**✏️ Editing:** select a row in the Recent measurements table → **Edit selected row**.

### 🌸 Flowering

Record flowering events with dates, colour, pollination notes, seed set, and an optional photo.

**✏️ Editing:** select a row in the Flowering history table → **Edit selected row**.

### 🪨 Soil Mix

Record what a plant is potted in, component by component with percentages.

- Click **+ Add row** for more than three components
- The running total updates as you enter percentages
- **✏️ Editing:** select a row in the Soil mix history → **Edit selected mix**
- **🗑️ Deleting:** select a row → **Delete selected mix**

> 💡 **Example mix for a Lithops:** Coarse river sand 40%, Pumice 30%, Akadama 20%, Decomposed granite 10%

### 📷 Photos

Upload photos for any plant. Thumbnails appear in the collection table, plant detail panel, and Gallery.

**To upload:**
1. Select the plant, set the date, optionally add a caption
2. Click **Browse** and select one or more image files (jpg, png, webp)
3. Click **Upload Photos**

**To delete a photo:** click the small red **×** button on any thumbnail.

> 💡 **iPhone users:** go to **Settings → Camera → Formats → Most Compatible** to save as JPEG instead of HEIC.

---

## 📅 Events & Notes

Log cultivation events for any plant.

| Event type | When to use |
|---|---|
| repot | Moved to a new pot |
| fertilise | Any feed application |
| treatment | Pesticide, fungicide, systemic drench |
| dormancy start / end | Beginning or end of dormancy period |
| other | Anything else |

> 💡 Events appear as **dashed blue lines on growth charts** so you can correlate treatments with growth changes.

**✏️ Editing:** select a row in the history table → **Edit selected row**.

---

## 📈 Growth Charts

Select a plant and a metric (height, width, or offsets) to see a growth curve. Dashed blue lines mark cultivation events — toggle with the checkbox. The **Growth summary** panel shows total change and rate per month.

The table at the bottom shows the latest measurement for every active plant.

---

## 🌱 Seeds & Germination

Manages **seed batches** separately from individual plants. A sowing tracks a whole tray; individual plants emerge from it later.

### 🌱 New Sowing

Register a seed batch when you sow. Key fields:

| Field | Example |
|---|---|
| Genus / Species | The species you are sowing |
| Sow date | When seeds went in |
| No. seeds sown | Total — used to calculate survival % |
| Seed origin | `Mesa Garden` · `own harvest Oct 2024` |
| Humidity enclosure | `plastic tray with clear lid` |
| Heat mat | ☑️ tick if used; add temperature details |
| Date first germinated | Defaults to sow date — adjust when germination occurs |

### 📋 Sowing Records

Browse all sowings. Click a row to expand the detail panel showing all sowing details, latest survival count, and a **Development Diary** — a chronological strip of photos attached to seedling counts for that batch.

**✏️ Editing:** select a row → **Edit selected sowing**.

### ✏️ Log Count / Event

**📊 Seedling counts** — record how many seedlings survive at any point in time. Do this periodically to build the survival chart.

**📷 Attaching a photo to a count:** click **📷 Attach photo to this count (optional)** below the Save Count button to expand the photo section. Choose a photo and click **Upload photo**. The photo will appear in the Development Diary on the Sowing Records tab when you click the sowing row.

**⚠️ Sowing events** — record treatments and problems: fungicide, pesticide, pathogen observations, thinning.

### 📈 Survival Chart

Shows seedling counts over time as a purple area chart. Toggle **Show as % of seeds sown** for mortality rate. Sowing events appear as orange dashed lines.

### 🎓 Graduate to Plant

When a seedling is large enough for its own pot:

1. Select the sowing
2. Optionally add a cultivar name
3. Set the date potted up individually
4. Click **Create Plant Record**

The plant is permanently linked to its sowing. A 🟣 **Sowing provenance** badge appears in the Collection detail panel.

---

## 🔧 Tools

### 🏷️ Labels

Generate a printable label sheet.

| Setting | Notes |
|---|---|
| Width / Height (mm) | Match your label stock — e.g. 55×19mm for small cactus labels |
| Font size | 7pt fits a lot on a small label |
| Fields to include | ☑️ Genus/species is in italics and larger than other fields |
| Which plants | All active plants, or just one selected plant |

Click **Download label sheet** → open the HTML file in Chrome → click **Print labels** → set paper size to match label dimensions, margins to minimum.

### 📤 Export to Excel

Download all your data as a formatted workbook with one sheet per table. Choose which tables to include and whether to export active plants only or all.

### 📥 Import from spreadsheet

Upload a CSV or XLSX, map your column names to database fields, and import in bulk.

**🗓️ Date formats handled automatically:**

| What's in your file | Stored as |
|---|---|
| `45778` (Excel serial) | `01/05/2025` |
| `1/05/2025` | `01/05/2025` |
| `September, 2025` | `01/09/2025` |
| `2025-03-05` (ISO) | `05/03/2025` |

> ⚠️ After importing, check a few records to confirm dates look right. If anything is wrong, select the imported rows and **Delete selected**, fix your spreadsheet, and re-import.

---

## 🖼️ Gallery

Browse all plant photos organised by taxonomy. Note: sowing/seedling photos are in the Sowing Records development diary, not the Gallery.

### Browsing

Photos are arranged: **Family** → **Genus** → **Species** → thumbnail grid.

Click any thumbnail to open it full size in the **lightbox overlay**. The lightbox steps through **all photos in the current filtered view**.

| Action | How |
|---|---|
| Next photo | Click **›** or press **→** |
| Previous photo | Click **‹** or press **←** |
| Close | Click **×**, press **Escape**, or click the dark background |

### 🔍 Filtering

| Control | How it works |
|---|---|
| **Family** dropdown | Shows only plants in that family |
| **Genus** dropdown | Cascades when a family is selected |
| **Search** box | Filters by species, cultivar, or caption |
| **Show plants with no photos** | Shows which species still need photographing |

### → Plant record link

Next to each species name, click **→ plant record** to jump to that plant in the Collection tab.

---

## ❓ Frequently asked questions

**Can I use this on multiple computers?**
Copy the entire `cactus_tracker` folder to the other machine. To keep two computers in sync, store the folder in Dropbox or OneDrive — don't run the app on both machines simultaneously.

**What happens to my data when I update the app?**
Nothing. Your data is in `collection.db` and is never touched by updates. Just replace `app.R` and run as normal.

**Can I have separate databases for different collections?**
Yes — copy the folder to a new location, delete `collection.db` from the copy, and run from that folder.

**I accidentally deleted a plant — can I get it back?**
Only if you have a backup. Use **Archive** rather than Delete when in doubt.

**My iPhone photos won't upload.**
Go to **Settings → Camera → Formats → Most Compatible** to save new photos as JPEG.

**Photos appear in the Gallery but not as thumbnails in the collection table.**
The collection table shows only the most recent photo per plant. Try pressing F5 to refresh.

**Where do seedling count photos appear?**
In the **Sowing Records** tab — click a sowing row to expand its detail panel and scroll down to the Development Diary section.

---

## ⌨️ Keyboard shortcuts

| Action | Shortcut |
|---|---|
| Select a row | Click |
| Sort by a column | Click the column header |
| Reverse the sort | Click the same header again |
| Next photo in lightbox | → arrow key |
| Previous photo in lightbox | ← arrow key |
| Close lightbox | Escape |

---

## 💬 Getting help and contributing

- 🐛 **Bug?** Open an issue on the GitHub page
- 💡 **Feature idea?** Open an issue
- 🔧 **Want to contribute?** Fork the repo and submit a pull request

If you find it useful, share it with your local succulent society or seed exchange network. 🌵
