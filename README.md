# 🌵 Cactus & Succulent Collection Tracker

> *A free, private, offline desktop app for serious succulent and cactus collectors.*

Track your plants, their growth, cultivation history, seed raising, labels, and more — all stored on your own computer. No subscription. No cloud account. No ads.

Built with **R Shiny** and **SQLite**.

---

## 🌿 Who this is for

This app was built for collectors who have outgrown a spreadsheet but don't want a generic garden app that wasn't designed with succulents in mind. It understands things like:

- ☀️ Summer vs ❄️ winter dormancy
- The difference between a measurement and a cultivation event
- Tracking a seed batch from sowing through to individual graduated plants
- Llifle links, native substrate notes, and subspecies names

Whether you have a windowsill of Lithops, a greenhouse of cacti, or an active seed-raising operation — this app is designed for you.

---

## ✨ Features

### 🪴 Collection management
- Full taxonomic records: family, genus, species, cultivar/form, common name
- Acquisition details: source, supplier, date acquired
- Origin and ecology: geographic origin, native substrate/geology, dormancy type
- Reference links to the Llifle Encyclopaedia of Succulents
- Toxicity and notable properties notes
- Searchable, filterable collection browser
- Soft archive (keeps all records) or permanent delete
- Bulk select — archive or delete multiple plants at once
- Duplicate a plant record to speed up entering similar specimens
- **Auto-fill family by genus** — update one *Lithops* with family Aizoaceae and the app offers to update all your other *Lithops* at once

### 📏 Growth tracking
- Record height, width, and offset/head/pad counts at any date
- Line charts of growth over time with cultivation events overlaid as markers
- Growth rate summary (units per month)
- Latest measurements for all active plants in one table

### 🌱 Cultivation records
- **📅 Events & notes:** repotting, watering, fertilising, treatments, dormancy start/end
- **🌸 Flowering records:** dates, colour, pollination method, seed set, seed harvest notes, and attached photos
- **🪨 Soil mixes:** component-by-component records with percentages, dated — fully editable after saving
- **📷 Photos:** upload one or more photos for any plant; thumbnails shown in the collection table and plant detail panel

### 🌱 Seeds & germination
- Sowing records: seed origin, seed age, sow date, number of seeds, enclosure, heat mat, lighting, watering
- Seedling count time series — record survivors at any interval
- 📈 Survival chart showing count or percentage over time, with treatment events overlaid
- Log fungicide treatments, pathogen observations (damping off, rot, fungus), thinning events
- Graduate individual seedlings into the main plant collection, with a permanent link back to their sowing provenance

### 🖼️ Gallery
- Browse all photos organised by Family → Genus → Species
- Filter by family, genus, or free-text search
- Click any thumbnail to open it full size with a lightbox overlay
- Step through the entire filtered gallery with arrow keys or on-screen buttons
- "Show plants with no photos" mode highlights which species still need photographing

### 🏷️ Labels
- Generate a printable label sheet as an HTML file — open in any browser and print
- Set any label size in mm — works with Dymo, Avery, or any label stock
- Choose which fields to include: name, origin, date planted, family, and more

### 📊 Export & import
- **📤 Export to Excel:** a formatted workbook with one sheet per table — plants, measurements, events, flowering, soil mixes, sowings, and seedling counts
- **📥 Import from CSV or Excel:** map your column names to the database fields and import in bulk. Handles mixed date formats automatically (Excel serial numbers, d/m/yyyy, named months, ISO dates)

### 🔒 Your data, your control
- Edit any record at any time — nothing is locked after entry
- Data stored in a standard SQLite file you can open with any SQLite tool
- Photos stored as ordinary image files — no proprietary formats

---

## 🚀 Getting started

📖 **New to R?** Start with **[INSTALL.md](INSTALL.md)** — it walks you through everything from a blank computer, step by step, with no programming experience required.

📖 **Ready to use the app?** See **[USER_GUIDE.md](USER_GUIDE.md)** — a full guide to every feature, with worked examples written for collectors.

---

## ⚡ Quick start (for R users)

```r
# Install required packages (once only)
install.packages(c("shiny", "shinydashboard", "shinyjs", "DBI", "RSQLite",
                   "ggplot2", "dplyr", "DT", "lubridate", "tools",
                   "openxlsx", "readxl"))

# Run the app
shiny::runApp("path/to/cactus_tracker")
```

---

## 💻 Requirements

| | |
|---|---|
| **R** | Version 4.1 or later — https://cran.r-project.org |
| **RStudio** | Recommended — https://posit.co/download/rstudio-desktop |
| **OS** | Windows, macOS, or Linux |
| **Disk space** | ~200 MB for packages; negligible for the app and database |
| **Internet** | Required for installation only — not needed to run the app |

---

## 💾 Your data

Everything lives in your `cactus_tracker` folder:

| Location | Contents |
|---|---|
| `collection.db` | All plant records, measurements, events, sowings, etc. |
| `www/photos/` | All uploaded photos |

> 💡 **To back up:** copy the entire `cactus_tracker` folder somewhere safe. Do this regularly.
>
> 💡 **To move to another computer:** copy the entire folder across — the app runs identically.
>
> 💡 **To update the app:** replace `app.R` only. Your data is never touched by updates.

---

## 🗺️ Known limitations

- 👤 The app is designed for single-user local use on a personal computer; networked or multi-user use is not supported

---

## 🤝 Contributing

Contributions are welcome!

- 🐛 **Found a bug?** Open an issue describing what happened
- 💡 **Have a feature idea?** Open an issue — collector feedback shapes the roadmap
- 🔧 **Want to contribute code?** Fork the repo, make your changes, and open a pull request

---

## 🙏 Acknowledgements

Built for the succulent and cactus collecting community. Inspired by the joy of a serious collection, and by the inadequacy of generic plant apps for managing one.

Species reference links connect to the [Llifle Encyclopaedia of Living Forms](https://www.llifle.com/Encyclopedia/SUCCULENTS/).

---

## 📄 Licence

MIT Licence — free to use, modify, and distribute. See `LICENSE` for details.
