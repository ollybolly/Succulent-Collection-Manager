# Installation Guide
## Cactus & Succulent Collection Tracker

This guide takes you from a blank computer to a running app, step by step. You do not need any programming experience. The app runs entirely on your own computer — no internet connection is needed once it is set up, and none of your data is sent anywhere.

---

## What you will install

| Software | What it is | Cost |
|---|---|---|
| **R** | The programming language the app is written in | Free |
| **RStudio** | A friendly interface for running R | Free |
| **R packages** | Add-on libraries the app depends on | Free |
| **DB Browser for SQLite** | Optional tool for viewing your data directly | Free |

Total disk space required: approximately 1.5 GB.

---

## Step 1 — Install R

R is the underlying language. You install it once and then mostly forget about it.

1. Open your web browser and go to **https://cran.r-project.org**
2. Click the link for your operating system:
   - **Windows:** click *Download R for Windows*, then *base*, then *Download R x.x.x for Windows*
   - **Mac:** click *Download R for macOS*, then choose the `.pkg` file matching your Mac (Apple Silicon = arm64, older Intel Mac = x86_64)
   - **Linux:** follow the instructions for your distribution
3. Run the downloaded installer and accept all the defaults. You do not need to change any settings.

> **How to tell it worked:** after installation, you should see an application called "R" in your programs list. You do not need to open it directly — RStudio will use it automatically.

---

## Step 2 — Install RStudio

RStudio is the interface you will actually use to run the app. Think of it like R is the engine and RStudio is the dashboard.

1. Go to **https://posit.co/download/rstudio-desktop**
2. Scroll down to *Download RStudio Desktop* and click the button for your operating system
3. Run the installer and accept all defaults

> **How to tell it worked:** open RStudio from your applications. You should see a window divided into panels. Don't worry about what they all mean — you only need the bottom-left panel called the **Console**.

---

## Step 3 — Download the app

1. Go to the GitHub page for this project
2. Click the green **Code** button, then **Download ZIP**
3. Unzip the downloaded file somewhere convenient, for example:
   - Windows: `C:\Users\YourName\Documents\cactus_tracker\`
   - Mac: `/Users/YourName/Documents/cactus_tracker/`

The folder should contain a file called `app.R`. That is the app.

> **Important:** keep the `app.R` file in its own dedicated folder. The app will create a database file (`collection.db`) and a photos folder (`www/photos/`) alongside it when you first run it. Do not move `app.R` into a folder with other projects.

---

## Step 4 — Install the required packages

Packages are add-on libraries that the app uses. You only need to do this once.

1. Open **RStudio**
2. Click in the **Console** panel (bottom left). You will see a `>` prompt.
3. Copy and paste the following line exactly, then press **Enter**:

```r
install.packages(c("shiny", "shinydashboard", "shinyjs", "DBI", "RSQLite",
                   "ggplot2", "dplyr", "DT", "lubridate", "tools",
                   "openxlsx", "readxl"))
```

4. R will download and install the packages. This takes 2–5 minutes depending on your internet speed. You will see a lot of text scrolling past — this is normal.

> **How to tell it worked:** when it finishes, you will see the `>` prompt again with no error messages. If you see a message asking about installing from source, type `n` and press Enter.

---

## Step 5 — Run the app

You need to do this each time you want to use the app.

**Option A — Open in RStudio (recommended)**

1. Open RStudio
2. Go to **File → Open File**
3. Navigate to your `cactus_tracker` folder and open `app.R`
4. Click the **Run App** button in the top-right corner of the editor panel

**Option B — From the Console**

1. Open RStudio
2. In the Console, type the following (replacing the path with your actual folder location) and press Enter:

```r
shiny::runApp("C:/Users/YourName/Documents/cactus_tracker")
```

On Mac:
```r
shiny::runApp("/Users/YourName/Documents/cactus_tracker")
```

**The app will open in your web browser.** It looks and works like a website, but it is running entirely on your computer. You do not need an internet connection to use it.

> **To stop the app:** go back to RStudio and click the **Stop** button (a red square) in the Console panel, or press **Escape**. Do not just close the browser tab — the app keeps running in the background until you stop it in RStudio.

---

## Step 6 — (Optional) Install DB Browser for SQLite

Your data is stored in a file called `collection.db` inside your `cactus_tracker` folder. This is a standard SQLite database file. DB Browser for SQLite lets you open it like a spreadsheet — useful for bulk edits, exporting data, or restoring archived plants.

1. Go to **https://sqlitebrowser.org/dl/**
2. Download and install the version for your operating system

You do not need this to use the app, but it is a handy safety net.

---

## Keeping your data safe

Your entire collection is stored in one file: `collection.db`. Photos are stored in `www/photos/`. To back up everything:

1. Close the app (stop it in RStudio)
2. Copy the entire `cactus_tracker` folder to a backup location (external drive, cloud storage, etc.)

**Recommended:** back up after every session, or at minimum weekly.

---

## Updating the app

When a new version of `app.R` is released:

1. Stop the app if it is running
2. Replace the old `app.R` with the new one
3. Leave `collection.db` and `www/photos/` exactly where they are — your data is safe
4. Run the app as normal

The app automatically updates the database structure on startup if needed. You never need to migrate your data manually.

---

## Troubleshooting

**The app opens but shows an error about a missing package**
Run `install.packages("packagename")` in the RStudio Console, replacing `packagename` with whatever is named in the error message.

**The browser opens but shows a grey screen**
Wait 10–15 seconds — the app sometimes takes a moment to start. If it stays grey, check the Console in RStudio for error messages.

**"could not find function" error**
A package did not install correctly. Re-run the install command from Step 4.

**The app crashes when I upload a photo**
The `www/photos/` folder may not have been created yet. In the RStudio Console, run:
```r
dir.create("www/photos", recursive = TRUE)
```
(Make sure the Console working directory is your cactus_tracker folder first — check with `getwd()`.)

**I accidentally deleted my database**
If you have a backup copy of `collection.db`, paste it back into the `cactus_tracker` folder. If not, the app will create a fresh empty database on next run.
