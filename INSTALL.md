# Installation Guide
## 🌵 Cactus & Succulent Collection Tracker

This guide takes you from a blank computer to a running app, step by step. You do not need any programming experience. The app runs entirely on your own computer — no internet connection is needed once it is set up, and none of your data is sent anywhere.

---

## What you will install

| Software | What it is | Cost |
|---|---|---|
| **R** | The programming language the app is written in | Free |
| **RStudio** | A friendly interface for running R | Free |
| **R packages** | Add-on libraries the app depends on | Free |
| **DB Browser for SQLite** | Optional tool for viewing your data directly | Free |

Total disk space required: approximately 800 MB, mostly taken up by RStudio (~600 MB) and R (~85 MB). The app and its packages add less than 100 MB on top of that.

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

RStudio is the interface you will use for the initial setup. After setup you won't need to open it again for day-to-day use.

1. Go to **https://posit.co/download/rstudio-desktop**
2. Scroll down to *Download RStudio Desktop* and click the button for your operating system
3. Run the installer and accept all defaults

> **How to tell it worked:** open RStudio from your applications. You should see a window divided into panels. The only panel you need is the bottom-left one called the **Console**.

---

## Step 3 — Download the app

1. Go to the GitHub page for this project
2. Click the green **Code** button, then **Download ZIP**
3. Unzip the downloaded file to a permanent location — somewhere you won't accidentally move or delete it:
   - Windows example: `C:\Users\YourName\Documents\cactus_tracker\`
   - Mac example: `/Users/YourName/Documents/cactus_tracker/`

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

4. R will download and install the packages. This takes 2–5 minutes. You will see a lot of text scrolling past — this is normal.

> **How to tell it worked:** when it finishes, you will see the `>` prompt again with no error messages. If you see a message asking about installing from source, type `n` and press Enter.

---

## Step 5 — Create a launch script

This is a small file that tells R to open the app. You create it once and never touch it again.

1. Open **Notepad** (Windows) or **TextEdit** (Mac — set to plain text mode via Format → Make Plain Text)
2. Paste the following, replacing the path with the actual location of your `cactus_tracker` folder:

**Windows:**
```r
shiny::runApp("C:/Users/YourName/Documents/cactus_tracker", launch.browser = TRUE)
```

**Mac:**
```r
shiny::runApp("/Users/YourName/Documents/cactus_tracker", launch.browser = TRUE)
```

> **Windows path tip:** use forward slashes `/` not backslashes `\`, even on Windows. R prefers them.

3. Save the file as `launch_cactus.R` inside your `cactus_tracker` folder

---

## Step 6 — Create a desktop shortcut (click-to-launch)

This is the step that makes the app feel like a normal desktop application. After this, you just click an icon and the app opens in your browser — no RStudio needed.

### 🪟 Windows

**First, find your R installation path:**

1. Open RStudio
2. In the Console, type `R.home("bin")` and press Enter
3. Note the path it returns — something like `C:/Program Files/R/R-4.4.1/bin`

**Create the shortcut:**

1. Right-click on your Desktop → **New → Shortcut**
2. In the location field, enter the following — replacing the R version and your username:

```
"C:\Program Files\R\R-4.4.1\bin\Rscript.exe" "C:\Users\YourName\Documents\cactus_tracker\launch_cactus.R"
```

> **Note:** there are two separate quoted sections. The first is the path to `Rscript.exe` (the R program), the second is the path to your launch script. Both need their own quotes because the paths contain spaces.

3. Click **Next**, name it `Cactus Tracker`, click **Finish**
4. Right-click the new shortcut → **Properties**
5. Click **Change Icon** → **Browse**
6. Navigate to your `cactus_tracker` folder and select `desert.ico` (included in the download)
7. Click **OK** → **Apply**
8. Optionally: right-click the shortcut → **Pin to taskbar** so it sits in your taskbar permanently

**To open the app:** double-click the shortcut (or click the taskbar icon). Your browser will open with the app after a few seconds. No RStudio window appears.

**To close the app:** close the browser tab. The R process continues running silently in the background — to stop it fully, press **Ctrl+Alt+Delete → Task Manager**, find `Rscript.exe` and end the task. Or simply restart your computer.

---

### 🍎 Mac

1. Open **TextEdit**, create a new plain text file (Format → Make Plain Text)
2. Paste the following, replacing the path:

```bash
#!/bin/bash
Rscript -e "shiny::runApp('/Users/YourName/Documents/cactus_tracker', launch.browser = TRUE)"
```

3. Save it as `launch_cactus.command` inside your `cactus_tracker` folder
4. Open **Terminal** and run the following to make it executable (replacing the path):

```bash
chmod +x "/Users/YourName/Documents/cactus_tracker/launch_cactus.command"
```

5. Double-clicking `launch_cactus.command` will now launch the app in your browser
6. To put it in the Dock: drag the `.command` file to the right-hand side of the Dock (the section after the divider line)

> **Mac tip:** you can change the icon by right-clicking the file → Get Info, then dragging an image onto the icon in the top-left of the info window.

**To close the app:** close the Terminal window that opened alongside the browser. This stops the R process cleanly.

---

## Step 7 — First launch

Double-click your new shortcut. The first time it runs:

1. A brief black command window may flash on screen (Windows only) — this is normal
2. Your default web browser opens automatically
3. The app appears — it may take 10–15 seconds the first time

You are ready to start adding plants.

---

## Step 8 — (Optional) Install DB Browser for SQLite

Your data is stored in a file called `collection.db` inside your `cactus_tracker` folder. DB Browser for SQLite lets you open it like a spreadsheet — useful for bulk edits, exporting, or recovering archived plants.

1. Go to **https://sqlitebrowser.org/dl/**
2. Download and install the version for your operating system

You do not need this to use the app, but it is a handy safety net.

---

## Keeping your data safe

Your entire collection lives in two places inside `cactus_tracker`:

| Location | Contents |
|---|---|
| `collection.db` | All plant records, measurements, events, sowings, etc. |
| `www/photos/` | All uploaded photos |

**To back up:** copy the entire `cactus_tracker` folder to a backup location (external drive, cloud storage, etc.). Do this regularly — after every session if you are entering a lot of data.

---

## Updating the app

When a new version of `app.R` is released:

1. Download the new `app.R` from GitHub
2. Replace the old `app.R` in your `cactus_tracker` folder
3. Leave `collection.db`, `www/photos/`, and `launch_cactus.R` exactly where they are — your data is never affected by updates
4. Launch as normal

The app automatically updates the database structure on first run after an update.

---

## Troubleshooting

**Nothing happens when I double-click the shortcut**
Check that the path to `Rscript.exe` in the shortcut is correct. In RStudio, run `R.home("bin")` to find the right path, then right-click the shortcut → Properties and update the Target field.

**The app opens but shows an error about a missing package**
Open RStudio and run `install.packages("packagename")`, replacing `packagename` with the name in the error message.

**The browser opens but shows a grey screen**
Wait 15–20 seconds — the app sometimes takes a moment on first launch. If it stays grey, open RStudio, paste in `shiny::runApp("path/to/cactus_tracker")` and check for error messages in the Console.

**"could not find function" error**
A package did not install correctly. Re-run the full install command from Step 4.

**The app crashes when I upload a photo**
The `www/photos/` folder may not exist yet. Open RStudio, set the working directory to your `cactus_tracker` folder with `setwd("path/to/cactus_tracker")`, then run `dir.create("www/photos", recursive = TRUE)`.

**I accidentally deleted my database**
If you have a backup of `collection.db`, paste it back into the `cactus_tracker` folder. If not, the app will create a fresh empty database on next launch — your records will be gone, which is why backups matter.

**Windows only: "Windows protected your PC" warning when launching**
Click **More info** → **Run anyway**. This happens because the shortcut points to a script rather than a signed application. It is safe to proceed.
