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
| 📷 Upload photos of a plant | **Record Data** → Photos |
| 🖼️ Browse all photos by taxonomy | **Gallery** tab |
| 📅 Log a repot, treatment, or other event | **Events & Notes** tab |
| 📈 See how a plant has grown over time | **Growth Charts** tab |
| 🌱 Manage a seed batch | **Seeds & Germination** tab |
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
| 🖼️ **Gallery** | Browse all photos organised by family, genus, and species |

---

## 🪴 Collection

### Browsing your plants

The Collection tab shows a searchable table of all your plants — active ones by default.

- 🔽 Use the **Status** dropdown to switch between active, archived, deceased, or gifted plants
- 🔍 Type in the **Search** box to filter by genus, species, family, or common name
  - e.g. type `Lithops` to see only living stones
  - e.g. type `Namibia` to find plants from that region
- 🔼🔽 Click any **column header** to sort; click again to reverse
- 🖼️ The leftmost column shows a small thumbnail of the most recent photo for each plant (if any)

### 🔎 Viewing a plant's full details

Click any row in the table. A **detail panel expands below** showing everything recorded for that plant — taxonomy, origin, dormancy, soil mix history, a Llifle link, and photo thumbnails. Click the same row again to collapse it.

### ☑️ Selecting multiple plants

| Action | How |
|---|---|
| Select one plant | Click its row |
| Select a range | Click the first row, then **Shift+click** the last |
| Add/remove a single row | **Ctrl+click** (Windows) or **Cmd+click** (Mac) |
| See how many are selected | Check the counter next to the buttons |

### 📦 Archiving plants

Archiving is the **safe option** for plants you no longer have. The plant disappears from the active list but every associated record — measurements, events, flowering history, photos — is kept. You can restore an archived plant at any time using DB Browser for SQLite.

1. Select one or more rows
2. Click **Archive selected** (🟠 orange button)
3. Confirm in the dialog

### 🗑️ Permanently deleting plants

Use this to remove bad imports or test entries where you don't need the records kept.

1. Select one or more rows
2. Click **Delete selected** (🔴 red button)
3. Read the warning carefully — **this cannot be undone**
4. Click **Delete permanently**

> 💡 **Clearing a bad import?** Use Shift+click to select all the unwanted rows at once, then Delete selected.

### ✏️ Editing a plant record

1. Click the plant's row to open its detail panel
2. Click **Edit plant** (🔵 blue button at the top of the panel)
3. A form opens with all current values pre-filled — change whatever needs updating
4. Click **Save changes**

> ✅ The table returns to your previous page position after saving, not back to page 1.

### 📋 Duplicating a plant

Useful when you have several plants of the same species with mostly identical details.

1. Click the plant's row to open the detail panel
2. Click **Duplicate** (grey button)
3. The app switches to Add Plant with all fields pre-filled
4. Change whatever differs — cultivar, acquisition date — and click **Add Plant**

---

## ➕ Add Plant

Use this to register a new plant in your collection.

### Fields explained

**🔬 Taxonomy**

| Field | Example |
|---|---|
| Family | `Aizoaceae` · `Cactaceae` · `Asphodelaceae` |
| Genus *(required)* | `Lithops` · `Echinopsis` · `Haworthia` |
| Species | `fulviceps` · `pachanoi` |
| Cultivar / form | `'Cole's Yellow'` · `v. aurantiaca` · `ssp. Bilobum` |
| Common name | `Living stone` · `San Pedro` |

> 💡 **Family auto-fill:** if you type a genus you've used before (e.g. `Lithops`), the family field fills in automatically with the known family (`Aizoaceae`). If the genus is new to your collection, the field stays blank and you fill it manually. When you save, the app also offers to update all other plants of the same genus to the same family — useful when you've just added family information for the first time.

> 💡 Family, origin, substrate, flower colour, and seed origin fields remember previous entries and suggest them as you type. You can always type something new that isn't in the list.

**🛒 Acquisition**

| Field | Notes |
|---|---|
| Source | Choose from: purchase, seed, cutting, offset, gift, other |
| Supplier / From | Nursery name, seed bank, person, or "own collection" |
| Date acquired | When you received or collected the plant |

**🌍 Origin & Ecology**

| Field | Example |
|---|---|
| Geographic origin | `Richtersveld, South Africa` · `Atacama Desert, Chile, 2000 m` |
| Native substrate | `quartzite gravel` · `limestone scree` · `loamy clay flats` |
| Dormancy | Summer dormant ☀️ · Winter dormant ❄️ · None |

**📚 Reference & Other**

| Field | Notes |
|---|---|
| Llifle URL | Paste the species-specific page URL from llifle.com |
| Toxicity | e.g. `highly toxic to livestock` · `latex a skin irritant` |
| General notes | Provenance, catalogue number, growing tips, anything else |

### ✏️ Example entry

> 🌿 **Conophytum bilobum** ssp. Bilobum  
> Family: `Aizoaceae` *(auto-filled when you type Conophytum)*  
> Source: `purchase` from `Kliphuis Nursery, Barrydale`  
> Acquired: `2025-03-15`  
> Origin: `Klihoogte, Western Cape, South Africa`  
> Substrate: `quartzite rubble`  
> Dormancy: ☀️ Summer dormant

---

## 📝 Record Data

This tab has four sub-tabs: **Measurements**, **Flowering**, **Soil Mix**, and **Photos**.

### 📏 Measurements

Record the size of a plant at a point in time. Do this periodically — monthly, seasonally, or whenever you think to — and the app builds a growth history automatically.

| Field | Notes |
|---|---|
| Plant | Select from the dropdown |
| Date | Defaults to today |
| Height (mm) | Overall height of the plant body, not including the pot |
| Width (mm) | Widest diameter |
| Offsets / heads / pads | Pups, heads on a multi-headed cactus, or pads on an Opuntia |
| Notes | Condition notes, anything unusual |

> 💡 **Example:** After six months you notice your *Astrophytum asterias* has grown noticeably. You record Height 38mm, Width 52mm. Six months later: Height 41mm, Width 61mm. The Growth Charts tab now shows you a curve and the growth rate in mm per month.

**✏️ Editing a measurement:** select the row in the Recent measurements table, then click **Edit selected row**.

---

### 🌸 Flowering

Record each flowering event — dates, colour, pollination, seed set, and photos.

| Field | Example |
|---|---|
| Flowering started / ended | Can be the same date for a single-day flower |
| Flower colour(s) | `bright yellow with orange centre` · `magenta with paler margins` |
| Pollination notes | `self-fertile, no action` · `hand-pollinated with brush from plant #12` |
| Seeds set | ☑️ Tick if successfully pollinated |
| Seed notes | Harvest date, quantity, storage location |
| Photo | Attach a photo of the flower (jpg, png, or webp) |

> 💡 **Example:** Your *Huernia pillansii* flowered in October. You record: started 12/10/2025, ended 19/10/2025, colour `pale yellow with dark red spots and central annulus`, seeds set ✅, seed notes `~30 seeds, paper envelope in fridge`.

---

### 🪨 Soil Mix

Record what soil mix a plant is potted in, and when. This lets you compare what a plant was in before and after a repot, and correlate mix changes with growth.

**Recording a new mix:**

1. Select the plant and set the date (e.g. the day you repotted)
2. Enter each component and its percentage — the running total updates as you type
3. Click **+ Add row** if you need more than three components
4. Add any notes (pH, where you sourced components)
5. Click **Save Soil Mix**

**✏️ Editing a saved mix:** select the row in the Soil mix history table, then click **Edit selected mix**. A modal opens pre-filled with the date, notes, and all components. You can change percentages, rename components, or add rows. Click **Save changes** when done.

**🗑️ Deleting a mix:** select the row and click **Delete selected mix**. This removes both the mix record and all its component records.

> 💡 **Example mix for a Lithops:**
>
> | Component | % |
> |---|---|
> | Coarse river sand | 40% |
> | Pumice | 30% |
> | Akadama | 20% |
> | Decomposed granite | 10% |
>
> Notes: `pH 6.5, pumice from Daltons, repotted from 5cm to 8cm terracotta`

---

### 📷 Photos

Upload one or more photos for any plant. Photos uploaded here appear in the collection table (as a thumbnail), in the plant detail panel, and in the Gallery tab.

**Uploading photos:**

1. Select the plant from the dropdown
2. Set the date the photo was taken
3. Click **Browse** and select one or more image files (jpg, png, or webp)
4. Optionally add a caption — this applies to all photos in the current upload
5. Click **Upload Photos**

> 💡 **Multiple photos at once:** hold Ctrl (Windows) or Cmd (Mac) when selecting files to pick several at once in the browser dialog.

> 💡 **iPhone photos:** iPhones save photos as HEIC format by default, which is not currently supported. To fix this, go to **Settings → Camera → Formats → Most Compatible** on your iPhone — this saves new photos as JPEG instead.

**The photo library** on the right shows all photos as square thumbnails. Filter by plant using the dropdown. Click a thumbnail to select it (highlighted in green), then click **Delete selected photo** to permanently remove both the image file and its record.

---

## 📅 Events & Notes

Use this for cultivation events that aren't measurements or soil changes.

**Available event types:**

| Event | When to use |
|---|---|
| 🪴 repot | Moved to a new pot (without recording the mix) |
| 💧 water | Ad hoc watering outside your normal routine |
| 🌿 fertilise | Any feed application |
| 🌸 flower | Observed flowering (quick log; use Record Data for full details) |
| 💊 treatment | Pesticide, fungicide, systemic drench |
| ✂️ propagate | Took a cutting or offset |
| ☀️ dormancy start | Moved to dry conditions, stopped watering |
| 🌱 dormancy end | Resumed watering, moved back to growing position |
| 📝 other | Anything else |

> 💡 These events appear as **dashed blue lines on growth charts** — so you can see whether a fertiliser application preceded a growth spurt, or whether a treatment coincided with a decline.

**✏️ Editing an event:** select its row in the history table, then click **Edit selected row**.

---

## 📈 Growth Charts

Select a plant and a metric to see a growth curve over time.

- 🟢 The **green line** shows the measurement at each recorded date
- 🔵 **Dashed blue lines** mark cultivation events — toggle with the checkbox
- The **Growth summary** panel shows total change and average growth rate per month

> 💡 For slow-growing plants like Lithops or ariocarpus, measurements over several years reveal patterns invisible week to week — which season they grow fastest, whether a new soil mix is performing better, how a repot affected the curve.

The table at the bottom shows the **latest measurement for every active plant** — useful for a periodic collection health check.

---

## 🌱 Seeds & Germination

This section manages **seed batches** separately from individual plants. A sowing is a whole tray; individual plants emerge from it later.

### 🌱 New Sowing

Register a new seed batch when you sow.

| Field | Example |
|---|---|
| Genus / Species | The species you are sowing |
| Sow date | When you put the seeds in |
| No. seeds sown | Total started — used to calculate survival % |
| Seed origin | `Mesa Garden catalogue` · `own harvest Oct 2024` · `seed swap` |
| Seed age | `fresh` · `2023 harvest` · `~3 years old` |
| Humidity enclosure | `50L plastic tub with lid` · `clear bag over tray` |
| Enclosure first opened | When you first cracked the lid for air circulation |
| Enclosure fully removed | When seedlings were fully exposed |
| Heat mat | ☑️ Tick if used; add temperature and timing details |
| Lighting | `16hr T5 fluorescent at 15cm for first 3 months` |
| Watering | `bottom-watered when surface just dry, approx weekly` |
| Date first germinated | Defaults to the sow date — adjust forward when germination occurs |

---

### 📋 Sowing Records

Browse all your sowings. **Click a row** to expand a full detail panel. Use **Edit selected sowing** to update any field. Use **Delete selected sowing** to remove the record (seedling counts and graduated plants are kept).

---

### ✏️ Log Count / Event

**📊 Seedling counts** — record how many seedlings are alive at any point in time.

> 💡 **Example count log for 50 seeds sown:**
>
> | Date | Surviving | Notes |
> |---|---|---|
> | 21 Mar 2025 | 38 | First count, germination still ongoing |
> | 1 Apr 2025 | 35 | Removed 3 with damping off |
> | 1 May 2025 | 33 | |
> | 1 Aug 2025 | 31 | Stable — growth accelerating |

**⚠️ Sowing events** — record treatments and problems:

| Event type | Example note |
|---|---|
| 🧪 fungicide treatment | `Chinosol 0.1% drench, preventative week 3` |
| 🐛 pesticide treatment | `Confidor drench for fungus gnat larvae` |
| 🍄 pathogen observed - fungus | `Damping off in corner, 3 seedlings removed` |
| ✂️ thinned | `Removed 8 weakest seedlings to improve airflow` |

---

### 📈 Survival Chart

Select a sowing to see a **purple area chart** of seedling counts over time. Toggle **Show as % of seeds sown** for mortality rate. ⚠️ Sowing events appear as orange dashed lines.

---

### 🎓 Graduate to Plant

When a seedling is large enough for its own pot:

1. Select the sowing it came from
2. Optionally add a cultivar name if it shows distinctive characteristics
3. Set the date you potted it up individually
4. Add notes — pot size, initial condition, which seedling from the batch
5. Click **Create Plant Record**

The new plant is permanently linked to its sowing. A 🟣 **Sowing provenance** badge appears in the Collection detail panel.

---

## 🔧 Tools

### 🏷️ Labels

Generate a printable label sheet for your plants.

| Setting | Notes |
|---|---|
| Width / Height (mm) | Match your label stock — e.g. 55×19mm for small cactus labels |
| Font size | 7pt fits a lot on a small label; increase for larger stock |
| Show border | Helpful for positioning; can be turned off for pre-cut labels |
| Fields to include | ☑️ Tick whichever you want — name, origin, date, family, notes, etc. |
| Which plants | All active plants, or just one selected plant |

Click **Download label sheet** → open the HTML file in Chrome or Edge → click **Print labels** → set paper size to match your label dimensions and margins to minimum.

---

### 📤 Export to Excel

1. ☑️ Tick which tables to include
2. Choose **Active plants only** or **All plants**
3. Click **Download Excel workbook**

Each table becomes its own sheet with auto-sized columns, named with today's date e.g. `cactus_collection_20250601.xlsx`.

---

### 📥 Import from spreadsheet

1. Click **Browse** and select your CSV or XLSX file
2. The **File preview** shows the first 6 rows
3. Use the **Map columns** dropdowns to match your column names to database fields
   - The app tries to auto-match by column name
   - Only **Genus** is required
4. Click **Import plants**

**🗓️ Date formats handled automatically:**

| What's in your file | Stored as |
|---|---|
| `45778` (Excel serial) | `2025-05-01` |
| `1/05/2025` (Australian) | `2025-05-01` |
| `September, 2025` | `2025-09-01` |
| `2025-03-05` (ISO) | `2025-03-05` |

> ⚠️ After importing, check a few records in Collection to confirm dates and origins look right. If anything is wrong, select all the imported rows and **Delete selected**, fix your spreadsheet, and re-import.

---

## 🖼️ Gallery

The Gallery tab shows all your photos organised by taxonomy — a visual overview of your entire collection.

### Browsing the gallery

Photos are arranged in a three-level hierarchy:

- **Family** — green header bar (e.g. Aizoaceae, Cactaceae)
  - **Genus** — bold italic heading with species count
    - **Species / cultivar** — italic line with photo count and a → plant record link
      - Thumbnail grid of all photos for that plant

Click any thumbnail to open it **full size** in a lightbox overlay. You can then step through all photos in the current filtered view — not just the species you clicked.

### 🔍 Filtering

Three controls at the top narrow what you see:

| Control | How it works |
|---|---|
| **Family** dropdown | Shows only plants in that family |
| **Genus** dropdown | Cascades automatically when a family is selected |
| **Search** box | Filters by species name, cultivar, or caption |
| **Show plants with no photos** | Reveals all plants that still need photographing |

> 💡 The "show plants with no photos" option is handy as a to-do list — it shows you at a glance which species in your collection aren't documented yet.

### 🔆 Lightbox

Click any thumbnail to open it full size. The lightbox steps through **all photos in the current filtered view** — so if you have filtered to a genus, you can arrow through every photo of that genus in one go.

| Action | How |
|---|---|
| Next photo | Click **›** or press **→** arrow key |
| Previous photo | Click **‹** or press **←** arrow key |
| Close | Click **×**, press **Escape**, or click the dark background |

The plant name, caption, and date are shown beneath each image.

### → Plant record link

Next to each species name there is a small **→ plant record** link. Clicking it takes you to the Collection tab for that plant so you can view its full cultivation history.

---

## ❓ Frequently asked questions

**Can I use this on multiple computers?**
Yes, but not simultaneously. Copy the entire `cactus_tracker` folder to the other machine. To keep two computers in sync, store the folder in Dropbox or OneDrive — just don't run the app on both machines at once.

**What happens to my data when I update the app?**
Nothing. Your data is in `collection.db`, which an update never touches. Just replace `app.R` and run as normal.

**Can I have separate databases — e.g. for a different collection?**
Yes. Copy the `cactus_tracker` folder to a new location, delete `collection.db` from the copy, and run the app from that folder. Each folder has its own independent database.

**The date I entered looks wrong — how do I fix it?**
Go to Collection → click the plant → **Edit plant** → correct the date. Dates should be entered as `YYYY-MM-DD` (e.g. `2025-05-01`) in edit forms.

**I accidentally deleted a plant — can I get it back?**
Only if you have a backup of `collection.db`. When in doubt, **Archive** rather than Delete — archived plants are always recoverable.

**My iPhone photos won't upload.**
iPhones save in HEIC format by default. Go to **Settings → Camera → Formats → Most Compatible** to switch to JPEG for new photos going forward.

**Can I attach more than one photo to a plant?**
Yes — upload multiple photos at once via Record Data → Photos. All photos for a plant appear as thumbnails in the detail panel and in the Gallery tab.

**Photos appear in the Gallery but I can't see thumbnails in the Collection table.**
The collection table shows only the most recent photo per plant. If a photo was uploaded but isn't showing, try refreshing the page (F5).

---

## ⌨️ Keyboard shortcuts

| Action | Shortcut |
|---|---|
| Select a row in a table | Click |
| Select a range | Shift+click the last row |
| Add/remove a row from selection | Ctrl+click (Windows) / Cmd+click (Mac) |
| Sort by a column | Click the column header |
| Reverse the sort | Click the same header again |
| Next photo in lightbox | → arrow key |
| Previous photo in lightbox | ← arrow key |
| Close lightbox | Escape |

---

## 💬 Getting help and contributing

This app is shared freely for the succulent collecting community.

- 🐛 **Bug?** Open an issue on the GitHub page
- 💡 **Feature idea?** Open an issue — collector feedback shapes the roadmap
- 🔧 **Want to contribute code?** Fork the repo, make your changes, submit a pull request

If you find it useful, share it with your local succulent society or seed exchange network. 🌵
