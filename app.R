# =============================================================================
# Cactus & Succulent Collection Tracker  —  Batch 3 update
# =============================================================================
# New in this version:
#   Edit:     Edit any plant, measurement, event, flowering, sowing, or
#             seedling count record via modal dialogs
#   Duplicate: Clone a plant record to Add Plant form
#   Labels:   Generate printable HTML labels (custom size, field selection)
#   Export:   Download full collection as Excel workbook (openxlsx)
#   Import:   Upload CSV/XLSX, map columns to DB fields, bulk import plants
# =============================================================================
# Install (run once):
#   install.packages(c("shiny","shinydashboard","shinyjs","DBI","RSQLite",
#                      "ggplot2","dplyr","DT","lubridate","tools","openxlsx",
#                      "readxl"))
# Run:
#   shiny::runApp("path/to/cactus_tracker/")
# =============================================================================

library(shiny)
library(shinydashboard)
library(shinyjs)
library(DBI)
library(RSQLite)
library(ggplot2)
library(dplyr)
library(DT)
library(lubridate)
library(tools)
library(openxlsx)
library(readxl)

# ── Constants ──────────────────────────────────────────────────────────────────
LLIFLE_BASE <- "https://www.llifle.com/Encyclopedia/SUCCULENTS/"
DB_PATH     <- "collection.db"
PHOTO_DIR   <- "www/photos"
if (!dir.exists(PHOTO_DIR)) dir.create(PHOTO_DIR, recursive = TRUE)

`%||%` <- function(x, y) {
  if (is.null(x) || (length(x) == 1 && (is.na(x) || x == ""))) y else x
}

na_str <- function(x) if (is.null(x) || is.na(x)) "" else as.character(x)

# ── Smart date parser for import ───────────────────────────────────────────────
# Handles: Excel serial integers, ISO strings, d/m/y, m/d/y, "Month, YYYY",
#          "Month YYYY", partial dates like "September, 2025" (stored as
#          first of month), and plain years.
smart_date <- function(x) {
  if (is.null(x) || is.na(x) || trimws(as.character(x)) == "") return(NA_character_)
  s <- trimws(as.character(x))

  # ── 1. Excel serial number (numeric string or actual numeric)
  num <- suppressWarnings(as.numeric(s))
  if (!is.na(num) && num > 1000 && num < 100000) {
    # Excel epoch is 1899-12-30; also handle the erroneous 1900 leap-year bug
    d <- as.Date(num - 2, origin = "1899-12-31")
    if (!is.na(d)) return(format(d))
  }

  # ── 2. Already ISO (YYYY-MM-DD)
  if (grepl("^\\d{4}-\\d{2}-\\d{2}$", s)) return(s)

  # ── 3. Named month formats: "September, 2025" / "September 2025"
  month_names <- c(january=1,february=2,march=3,april=4,may=5,june=6,
                   july=7,august=8,september=9,october=10,november=11,december=12)
  m <- regmatches(s, regexpr("(?i)(january|february|march|april|may|june|july|august|september|october|november|december)",s))
  if (length(m) > 0) {
    yr <- regmatches(s, regexpr("\\d{4}", s))
    if (length(yr) > 0) {
      mo <- month_names[tolower(m)]
      return(format(as.Date(paste0(yr, "-", sprintf("%02d", mo), "-01"))))
    }
  }

  # ── 4. d/m/yyyy or m/d/yyyy — try d/m first (Australian convention)
  if (grepl("^\\d{1,2}/\\d{1,2}/\\d{4}$", s)) {
    parts <- as.integer(strsplit(s, "/")[[1]])
    d <- parts[1]; m <- parts[2]; y <- parts[3]
    # If day > 12 it must be d/m/y; otherwise assume d/m/y (Australian)
    candidate <- tryCatch(as.Date(sprintf("%04d-%02d-%02d", y, m, d)), error=function(e) NA)
    if (!is.na(candidate) && m <= 12) return(format(candidate))
    # Fall back to m/d/y
    candidate2 <- tryCatch(as.Date(sprintf("%04d-%02d-%02d", y, d, m)), error=function(e) NA)
    if (!is.na(candidate2)) return(format(candidate2))
  }

  # ── 5. yyyy/mm/dd
  if (grepl("^\\d{4}/\\d{2}/\\d{2}$", s))
    return(format(tryCatch(as.Date(s, "%Y/%m/%d"), error=function(e) NA)))

  # ── 6. Plain year "2025" — store as 1 Jan of that year
  if (grepl("^\\d{4}$", s)) return(paste0(s, "-01-01"))

  # ── 7. Let lubridate have a go
  d <- tryCatch(suppressWarnings(lubridate::parse_date_time(s,
    orders = c("dmy","mdy","ymd","dBY","BY","BdY"),
    quiet = TRUE)), error=function(e) NA)
  if (!is.na(d)) return(format(as.Date(d)))

  NA_character_  # give up gracefully
}

# ── Database ───────────────────────────────────────────────────────────────────
init_db <- function(con) {
  dbExecute(con, "CREATE TABLE IF NOT EXISTS plants (
    id INTEGER PRIMARY KEY AUTOINCREMENT, genus TEXT NOT NULL, species TEXT,
    cultivar TEXT, common_name TEXT, source TEXT, supplier TEXT, acquired DATE,
    status TEXT DEFAULT 'active', notes TEXT)")
  for (col in c("family TEXT","origin_geo TEXT","origin_soil TEXT",
                "dormancy TEXT DEFAULT 'none'","llifle_url TEXT",
                "toxicity TEXT","sowing_id INTEGER"))
    tryCatch(dbExecute(con, paste("ALTER TABLE plants ADD COLUMN", col)),
             error=function(e) invisible(NULL))
  dbExecute(con, "CREATE TABLE IF NOT EXISTS measurements (
    id INTEGER PRIMARY KEY AUTOINCREMENT, plant_id INTEGER NOT NULL REFERENCES plants(id),
    meas_date DATE NOT NULL, height_mm REAL, width_mm REAL, offsets INTEGER, notes TEXT)")
  dbExecute(con, "CREATE TABLE IF NOT EXISTS events (
    id INTEGER PRIMARY KEY AUTOINCREMENT, plant_id INTEGER NOT NULL REFERENCES plants(id),
    event_date DATE NOT NULL, event_type TEXT NOT NULL, notes TEXT)")
  dbExecute(con, "CREATE TABLE IF NOT EXISTS flowering (
    id INTEGER PRIMARY KEY AUTOINCREMENT, plant_id INTEGER NOT NULL REFERENCES plants(id),
    start_date DATE, end_date DATE, flower_colour TEXT, pollination_notes TEXT,
    seeds_set INTEGER DEFAULT 0, seed_notes TEXT, notes TEXT)")
  dbExecute(con, "CREATE TABLE IF NOT EXISTS photos (
    id INTEGER PRIMARY KEY AUTOINCREMENT, plant_id INTEGER NOT NULL REFERENCES plants(id),
    photo_date DATE NOT NULL, file_name TEXT NOT NULL, caption TEXT,
    flowering_id INTEGER REFERENCES flowering(id))")
  dbExecute(con, "CREATE TABLE IF NOT EXISTS soil_mixes (
    id INTEGER PRIMARY KEY AUTOINCREMENT, plant_id INTEGER NOT NULL REFERENCES plants(id),
    date_set DATE NOT NULL, notes TEXT)")
  dbExecute(con, "CREATE TABLE IF NOT EXISTS soil_mix_components (
    id INTEGER PRIMARY KEY AUTOINCREMENT, mix_id INTEGER NOT NULL REFERENCES soil_mixes(id),
    component TEXT NOT NULL, percentage REAL)")
  dbExecute(con, "CREATE TABLE IF NOT EXISTS sowings (
    id INTEGER PRIMARY KEY AUTOINCREMENT, genus TEXT NOT NULL, species TEXT,
    cultivar TEXT, sow_date DATE NOT NULL, seed_origin TEXT, seed_age TEXT,
    n_seeds INTEGER, date_first_germ DATE, enclosure_type TEXT,
    enclosure_opened DATE, enclosure_removed DATE, heat_mat INTEGER DEFAULT 0,
    heat_mat_notes TEXT, lights_notes TEXT, watering_notes TEXT, notes TEXT)")
  dbExecute(con, "CREATE TABLE IF NOT EXISTS seedling_counts (
    id INTEGER PRIMARY KEY AUTOINCREMENT, sowing_id INTEGER NOT NULL REFERENCES sowings(id),
    count_date DATE NOT NULL, n_surviving INTEGER, notes TEXT)")
  dbExecute(con, "CREATE TABLE IF NOT EXISTS sowing_events (
    id INTEGER PRIMARY KEY AUTOINCREMENT, sowing_id INTEGER NOT NULL REFERENCES sowings(id),
    event_date DATE NOT NULL, event_type TEXT NOT NULL, notes TEXT)")
}

get_con <- function() { con <- dbConnect(RSQLite::SQLite(), DB_PATH); init_db(con); con }

# ── Helpers ────────────────────────────────────────────────────────────────────
plant_label <- function(df) paste0(df$id, " | ", df$genus,
  ifelse(!is.na(df$species)  & df$species  != "", paste0(" ", df$species), ""),
  ifelse(!is.na(df$cultivar) & df$cultivar != "", paste0(" '", df$cultivar, "'"), ""))

sowing_label <- function(df) paste0(df$id, " | ", df$genus,
  ifelse(!is.na(df$species) & df$species != "", paste0(" ", df$species), ""),
  " [sown ", df$sow_date, "]")

distinct_vals <- function(con, tbl, col) {
  dbGetQuery(con, sprintf(
    "SELECT DISTINCT %s FROM %s WHERE %s IS NOT NULL AND %s != '' ORDER BY %s",
    col, tbl, col, col, col))[[col]]
}

# ── Label HTML generator ───────────────────────────────────────────────────────
make_label_html <- function(plants_df, fields, w_mm, h_mm, font_pt, border) {
  border_css <- if (border) "border: 0.5pt solid #888;" else ""
  field_labels <- c(
    genus_species = "Name", family = "Family", common_name = "Common",
    origin_geo = "Origin", origin_soil = "Substrate", acquired = "Planted",
    source = "Source", supplier = "Supplier", dormancy = "Dormancy",
    toxicity = "Toxicity", notes = "Notes", llifle_url = "Llifle"
  )

  label_divs <- vapply(seq_len(nrow(plants_df)), function(i) {
    r    <- plants_df[i, ]
    name <- paste(na_str(r$genus), na_str(r$species))
    if (!is.na(r$cultivar) && r$cultivar != "")
      name <- paste0(name, " '", r$cultivar, "'")
    lines <- character(0)
    if ("genus_species" %in% fields)
      lines <- c(lines, sprintf('<div style="font-weight:bold;font-size:%dpt;line-height:1.2;">%s</div>',
                                 font_pt, htmlEscape(trimws(name))))
    for (f in setdiff(fields, "genus_species")) {
      val <- na_str(r[[f]])
      if (nchar(val) == 0) next
      lbl <- field_labels[[f]]
      lines <- c(lines, sprintf(
        '<div style="font-size:%dpt;line-height:1.2;"><span style="font-weight:600;">%s:</span> %s</div>',
        max(font_pt - 1L, 5L), htmlEscape(lbl), htmlEscape(val)))
    }
    paste0(sprintf(
      '<div style="width:%smm;height:%smm;padding:1mm;box-sizing:border-box;
       overflow:hidden;display:inline-block;vertical-align:top;%s">',
      w_mm, h_mm, border_css),
      paste(lines, collapse=""), "</div>")
  }, character(1))

  paste0('<!DOCTYPE html><html><head><meta charset="UTF-8">
<style>
  @page { size: ', w_mm, 'mm ', h_mm, 'mm; margin: 0; }
  @media print { body { margin:0; } .no-print { display:none; } }
  body { font-family: Arial, sans-serif; margin: 4mm; }
  .label-wrap { display:flex; flex-wrap:wrap; gap:2mm; }
  button.no-print { margin-bottom:6mm; padding:6px 16px;
    background:#2e7d32; color:#fff; border:none; border-radius:4px;
    font-size:14px; cursor:pointer; }
</style></head><body>
<button class="no-print" onclick="window.print()">Print labels</button>
<div class="label-wrap">',
    paste(label_divs, collapse="\n"),
    '</div></body></html>')
}

# Simple HTML escape
htmlEscape <- function(x) {
  x <- gsub("&",  "&amp;",  x)
  x <- gsub("<",  "&lt;",   x)
  x <- gsub(">",  "&gt;",   x)
  x <- gsub('"',  "&quot;", x)
  x
}


# ══════════════════════════════════════════════════════════════════════════════
# UI
# ══════════════════════════════════════════════════════════════════════════════
ui <- dashboardPage(
  skin = "green",
  dashboardHeader(title = "\U0001f335 Collection Tracker"),
  dashboardSidebar(sidebarMenu(id="sidebar",
    menuItem("Collection",        tabName="collection",  icon=icon("seedling")),
    menuItem("Add Plant",         tabName="add_plant",   icon=icon("plus")),
    menuItem("Record Data",       tabName="record_data", icon=icon("pen-to-square")),
    menuItem("Events & Notes",    tabName="events",      icon=icon("calendar-days")),
    menuItem("Growth Charts",     tabName="charts",      icon=icon("chart-line")),
    menuItem("Seeds & Germination",tabName="seeds",      icon=icon("circle-dot")),
    menuItem("Tools",             tabName="tools",       icon=icon("wrench")),
    menuItem("Gallery",           tabName="gallery",     icon=icon("images"))
  )),
  dashboardBody(
    useShinyjs(),
    tags$head(tags$style(HTML("
      .detail-label{font-weight:600;color:#555;font-size:11px;text-transform:uppercase;letter-spacing:.05em;}
      .photo-thumb{max-width:140px;max-height:140px;margin:5px;border-radius:6px;
                   border:1px solid #ddd;transition:opacity .2s;}
      .photo-thumb:hover{opacity:.85;}
      .llifle-link{color:#2e7d32;font-weight:600;}
      .dorm-badge{display:inline-block;padding:2px 9px;border-radius:10px;font-size:12px;font-weight:600;}
      .dorm-summer{background:#fff3e0;color:#e65100;}
      .dorm-winter{background:#e3f2fd;color:#1565c0;}
      .seed-badge{display:inline-block;padding:2px 9px;border-radius:10px;font-size:12px;font-weight:600;background:#f3e5f5;color:#6a1b9a;}
      .label-preview{border:1px solid #ccc;border-radius:6px;background:#fafafa;padding:10px;min-height:80px;}
      .import-preview{font-size:12px;}
      .gallery-thumb{width:110px;height:110px;object-fit:cover;border-radius:6px;
                     border:2px solid #e0e0e0;cursor:pointer;transition:transform .15s,border-color .15s;}
      .gallery-thumb:hover{transform:scale(1.06);border-color:#2e7d32;}
      .gallery-card{display:inline-block;text-align:center;width:120px;vertical-align:top;
                    margin:5px;padding:4px;border-radius:8px;}
      .gallery-section{margin-bottom:18px;}
      .gallery-genus{font-size:15px;font-weight:700;color:#2e7d32;margin:14px 0 4px 0;
                     border-bottom:2px solid #c8e6c9;padding-bottom:3px;}
      .gallery-species{font-size:12px;color:#555;font-style:italic;margin:8px 0 4px 6px;}
      .gallery-caption{font-size:10px;color:#777;margin-top:3px;word-break:break-word;
                       max-width:110px;white-space:nowrap;overflow:hidden;text-overflow:ellipsis;}
      .gallery-date{font-size:10px;color:#aaa;}
      .gallery-filter{margin-bottom:12px;}

    "))),

    tabItems(

      # ══ COLLECTION ═══════════════════════════════════════════════════════════
      tabItem(tabName="collection",
        fluidRow(box(width=12,title="My Collection",status="success",solidHeader=TRUE,
          fluidRow(
            column(3,selectInput("col_status","Status",
              choices=c("All","active","archived","deceased","gifted"),selected="active")),
            column(4,textInput("col_search","Search",
              placeholder="genus, species, family, common name...")),
            column(5,br(),
              actionButton("col_delete_btn","Archive selected",
                class="btn-warning btn-sm",icon=icon("box-archive")),
              actionButton("col_hard_delete_btn","Delete selected",
                class="btn-danger btn-sm",icon=icon("trash"),
                style="margin-left:6px;"),
              tags$span(id="col_sel_count",style="margin-left:10px;color:#555;font-size:13px;",
                textOutput("col_sel_count",inline=TRUE))
            )
          ),
          DTOutput("collection_table")
        )),
        uiOutput("plant_detail_panel")
      ),

      # ══ ADD PLANT ════════════════════════════════════════════════════════════
      tabItem(tabName="add_plant",
        fluidRow(
          box(width=7,title="Add New Plant",status="success",solidHeader=TRUE,
            uiOutput("ap_prefill_banner"),
            h4("Taxonomy"),
            fluidRow(
              column(6,selectizeInput("ap_family","Family",choices=NULL,
                options=list(create=TRUE,placeholder="e.g. Cactaceae"))),
              column(6,textInput("ap_genus","Genus *",placeholder="e.g. Echinopsis"))
            ),
            fluidRow(
              column(6,textInput("ap_species","Species",placeholder="e.g. pachanoi")),
              column(6,textInput("ap_cultivar","Cultivar / form",placeholder="e.g. 'Fuzzy Monster'"))
            ),
            textInput("ap_common","Common name",placeholder="e.g. San Pedro"),
            hr(),h4("Acquisition"),
            fluidRow(
              column(6,selectInput("ap_source","Source",
                choices=c("purchase","seed","cutting","offset","gift","other"))),
              column(6,textInput("ap_supplier","Supplier / From",
                placeholder="nursery, seed bank, person..."))
            ),
            dateInput("ap_acquired","Date acquired",value=Sys.Date()),
            hr(),
            tags$p(tags$em("If grown from seed, link to sowing record:",style="color:#666;font-size:13px;")),
            selectInput("ap_sowing","Sowing (optional)",choices=NULL),
            hr(),h4("Origin & Ecology"),
            selectizeInput("ap_origin_geo","Geographic origin",choices=NULL,
              options=list(create=TRUE,placeholder="e.g. Andean foothills, Peru, 2000-3000 m")),
            selectizeInput("ap_origin_soil","Native substrate / geology",choices=NULL,
              options=list(create=TRUE,placeholder="e.g. limestone scree, granitic sandy soil")),
            selectInput("ap_dormancy","Dormancy",
              choices=c("None"="none","Summer dormant"="summer","Winter dormant"="winter")),
            hr(),h4("Reference & Other"),
            textInput("ap_llifle","Llifle URL",placeholder=LLIFLE_BASE),
            tags$small(tags$a("Open Llifle index \u2197",href=LLIFLE_BASE,target="_blank",class="llifle-link")),
            br(),br(),
            textAreaInput("ap_toxicity","Toxicity / notable properties",rows=2,
              placeholder="e.g. mildly toxic if ingested; latex a skin irritant"),
            textAreaInput("ap_notes","General notes",rows=3),
            actionButton("ap_submit","Add Plant",class="btn-success btn-lg",icon=icon("seedling")),
            br(),br(),uiOutput("ap_feedback_ui")
          ),
          box(width=5,title="Collection stats",status="info",verbatimTextOutput("quick_stats"))
        )
      ),

      # ══ RECORD DATA ══════════════════════════════════════════════════════════
      tabItem(tabName="record_data",
        fluidRow(tabBox(width=12,id="record_tabs",

          tabPanel(title=tagList(icon("ruler")," Measurements"),
            fluidRow(
              column(5,
                selectInput("m_plant","Plant *",choices=NULL),
                dateInput("m_date","Date",value=Sys.Date()),
                numericInput("m_height","Height (mm)",value=NA,min=0),
                numericInput("m_width","Width (mm)",value=NA,min=0),
                numericInput("m_offsets","Offsets / heads / pads",value=NA,min=0),
                textAreaInput("m_notes","Notes",rows=2),
                actionButton("m_submit","Save Measurement",class="btn-success"),
                br(),br(),textOutput("m_feedback")
              ),
              column(7,
                h4("Recent measurements"),
                DTOutput("recent_measurements"),
                br(),
                actionButton("m_edit_btn","Edit selected row",
                  class="btn-sm btn-default",icon=icon("pen")),
                actionButton("m_del_btn","Delete selected row",
                  class="btn-sm btn-danger",icon=icon("trash"),style="margin-left:6px;")
              )
            )
          ),

          tabPanel(title=tagList(icon("star")," Flowering"),
            fluidRow(
              column(5,
                selectInput("fl_plant","Plant *",choices=NULL),
                fluidRow(
                  column(6,dateInput("fl_start","Started",value=Sys.Date())),
                  column(6,dateInput("fl_end","Ended",value=Sys.Date()))
                ),
                selectizeInput("fl_colour","Flower colour(s)",choices=NULL,
                  options=list(create=TRUE,placeholder="e.g. cerise pink with white throat")),
                textAreaInput("fl_pollination","Pollination notes",rows=2,
                  placeholder="self-fertile, hand-pollinated, bee visits..."),
                checkboxInput("fl_seeds","Seeds set",value=FALSE),
                conditionalPanel("input.fl_seeds == true",
                  textAreaInput("fl_seed_notes","Seed notes",rows=2,
                    placeholder="harvest date, quantity, storage...")),
                textAreaInput("fl_notes","Other notes",rows=2),
                hr(),
                h5("Attach photo (optional)"),
                fileInput("fl_photo",NULL,
                  accept=c("image/jpeg","image/png","image/jpg","image/webp"),
                  buttonLabel="Choose photo..."),
                textInput("fl_photo_caption","Caption"),
                actionButton("fl_submit","Save Flowering Record",
                  class="btn-success",icon=icon("star")),
                br(),br(),textOutput("fl_feedback")
              ),
              column(7,
                h4("Flowering history"),
                DTOutput("flowering_history"),
                br(),
                actionButton("fl_edit_btn","Edit selected row",
                  class="btn-sm btn-default",icon=icon("pen")),
                actionButton("fl_del_btn","Delete selected row",
                  class="btn-sm btn-danger",icon=icon("trash"),style="margin-left:6px;")
              )
            )
          ),

          tabPanel(title=tagList(icon("layer-group")," Soil Mix"),
            fluidRow(
              column(5,
                selectInput("sm_plant","Plant *",choices=NULL),
                dateInput("sm_date","Date recorded",value=Sys.Date()),
                h5("Components"),
                tags$p(tags$em("Type or select component; enter % for each.",
                  style="color:#666;font-size:13px;")),
                uiOutput("soil_component_rows"),
                fluidRow(
                  column(6,actionButton("sm_add_row","+ Add row",
                    class="btn-sm btn-default",style="margin-top:6px;")),
                  column(6,tags$div(style="text-align:right;font-weight:bold;padding-top:10px;",
                    textOutput("sm_total_pct",inline=TRUE)))
                ),
                br(),
                textAreaInput("sm_notes","Notes",rows=2,
                  placeholder="pH, sterilised, component sources..."),
                actionButton("sm_submit","Save Soil Mix",
                  class="btn-success",icon=icon("layer-group")),
                br(),br(),textOutput("sm_feedback")
              ),
              column(7,
                h4("Soil mix history"),
                DTOutput("soil_mix_history"),
                br(),
                actionButton("sm_edit_btn","Edit selected mix",
                  class="btn-sm btn-default",icon=icon("pen")),
                actionButton("sm_del_btn","Delete selected mix",
                  class="btn-sm btn-danger",icon=icon("trash"),
                  style="margin-left:6px;")
              )
            )
          ),

          tabPanel(title=tagList(icon("camera")," Photos"),
            fluidRow(
              column(5,
                h4("Upload photos"),
                tags$p(tags$em("Attach one or more photos to any plant. Thumbnails appear in the collection table and plant detail panel.",style="color:#555;font-size:13px;")),
                selectInput("ph_plant","Plant *",choices=NULL),
                dateInput("ph_date","Date taken",value=Sys.Date()),
                fileInput("ph_files","Choose photo(s)",
                  accept=c("image/jpeg","image/png","image/jpg","image/webp"),
                  multiple=TRUE,
                  buttonLabel="Browse..."),
                textInput("ph_caption","Caption (applies to all selected photos)"),
                actionButton("ph_submit","Upload Photos",
                  class="btn-success",icon=icon("camera")),
                br(),br(),uiOutput("ph_feedback_ui")
              ),
              column(7,
                h4("Photo library"),
                selectInput("ph_filter","Filter by plant",choices=NULL),
                uiOutput("ph_gallery"),
                br(),
                actionButton("ph_del_btn","Delete selected photo",
                  class="btn-sm btn-danger",icon=icon("trash")),
                uiOutput("ph_sel_ui")
              )
            )
          )
        ))
      ),

      # ══ EVENTS & NOTES ════════════════════════════════════════════════════════
      tabItem(tabName="events",
        fluidRow(
          box(width=5,title="Log Event",status="success",solidHeader=TRUE,
            selectInput("e_plant","Plant *",choices=NULL),
            dateInput("e_date","Date",value=Sys.Date()),
            selectInput("e_type","Event type",
              choices=c("repot","water","fertilise","flower","treatment",
                        "propagate","dormancy start","dormancy end","other")),
            textAreaInput("e_notes","Notes",rows=3),
            actionButton("e_submit","Save Event",class="btn-success"),
            br(),br(),textOutput("e_feedback")
          ),
          box(width=7,title="Event History",status="info",solidHeader=TRUE,
            selectInput("e_filter_plant","Filter by plant",choices=NULL),
            DTOutput("event_history"),
            br(),
            actionButton("e_edit_btn","Edit selected row",
              class="btn-sm btn-default",icon=icon("pen")),
            actionButton("e_del_btn","Delete selected row",
              class="btn-sm btn-danger",icon=icon("trash"),style="margin-left:6px;")
          )
        )
      ),

      # ══ GROWTH CHARTS ═════════════════════════════════════════════════════════
      tabItem(tabName="charts",
        fluidRow(
          box(width=4,title="Options",status="success",solidHeader=TRUE,
            selectInput("ch_plant","Plant",choices=NULL),
            selectInput("ch_metric","Metric",
              choices=c("Height (mm)"="height_mm","Width (mm)"="width_mm",
                        "Offsets / heads"="offsets")),
            checkboxInput("ch_events","Overlay cultivation events",value=TRUE),
            hr(),h4("Growth summary"),verbatimTextOutput("ch_summary")
          ),
          box(width=8,title="Growth over time",status="info",solidHeader=TRUE,
            plotOutput("growth_plot",height="420px"))
        ),
        fluidRow(box(width=12,title="All active plants - latest measurements",
            status="info",solidHeader=TRUE,DTOutput("latest_measurements")))
      ),

      # ══ SEEDS & GERMINATION ═══════════════════════════════════════════════════
      tabItem(tabName="seeds",
        fluidRow(tabBox(width=12,id="seed_tabs",

          tabPanel(title=tagList(icon("circle-dot")," New Sowing"),
            fluidRow(
              column(6,
                h4("Species"),
                fluidRow(
                  column(6,textInput("sw_genus","Genus *",placeholder="e.g. Astrophytum")),
                  column(6,textInput("sw_species","Species",placeholder="e.g. asterias"))
                ),
                textInput("sw_cultivar","Cultivar / form",placeholder="optional"),
                hr(),h4("Seed Details"),
                fluidRow(
                  column(6,dateInput("sw_sow_date","Sow date",value=Sys.Date())),
                  column(6,numericInput("sw_n_seeds","No. seeds sown",value=NA,min=1))
                ),
                selectizeInput("sw_origin","Seed origin",choices=NULL,
                  options=list(create=TRUE,placeholder="e.g. Mesa Garden, own harvest 2023...")),
                textInput("sw_seed_age","Seed age / harvest date",
                  placeholder="e.g. fresh, 2023, ~2 years old"),
                hr(),h4("Growing Conditions"),
                textInput("sw_enclosure","Humidity enclosure type",
                  placeholder="e.g. plastic tray with clear lid"),
                fluidRow(
                  column(6,dateInput("sw_enc_opened","Enclosure first opened",value=NA)),
                  column(6,dateInput("sw_enc_removed","Enclosure fully removed",value=NA))
                ),
                fluidRow(
                  column(4,checkboxInput("sw_heat_mat","Heat mat",value=FALSE)),
                  column(8,conditionalPanel("input.sw_heat_mat == true",
                    textInput("sw_heat_notes","Heat mat details",
                      placeholder="e.g. 25C, 24hr for 4 weeks")))
                ),
                textAreaInput("sw_lights","Lighting regime",rows=2,
                  placeholder="e.g. 16hr T5 fluorescent at 15cm"),
                textAreaInput("sw_watering","Watering regime",rows=2,
                  placeholder="e.g. bottom-water when surface dry; ~weekly"),
                textAreaInput("sw_notes","Other notes",rows=3),
                actionButton("sw_submit","Save Sowing Record",
                  class="btn-success btn-lg",icon=icon("circle-dot")),
                br(),br(),uiOutput("sw_feedback_ui")
              ),
              column(6,
                h4("First germination"),
                dateInput("sw_first_germ","Date first germinated",value=NA),
                tags$p(tags$em("Leave blank if not yet germinated.",
                  style="color:#888;font-size:13px;")),
                hr(),h4("All sowings"),DTOutput("sowings_table_new")
              )
            )
          ),

          tabPanel(title=tagList(icon("list")," Sowing Records"),
            fluidRow(column(12,DTOutput("sowings_table_main"),br())),
            fluidRow(column(12,
              actionButton("sw_edit_btn","Edit selected sowing",
                class="btn-sm btn-default",icon=icon("pen")),
              actionButton("sw_del_btn","Delete selected sowing",
                class="btn-sm btn-danger",icon=icon("trash"),style="margin-left:6px;")
            )),
            br(),
            uiOutput("sowing_detail_panel")
          ),

          tabPanel(title=tagList(icon("pen-to-square")," Log Count / Event"),
            fluidRow(
              column(5,
                selectInput("sl_sowing","Sowing *",choices=NULL),
                hr(),h4("Seedling count"),
                tags$p(tags$em("Record surviving seedlings at any point in time.",
                  style="color:#666;font-size:13px;")),
                dateInput("sl_date","Date",value=Sys.Date()),
                numericInput("sl_n","Surviving seedlings",value=NA,min=0),
                textAreaInput("sl_notes","Notes",rows=2,
                  placeholder="condition, vigour, size notes..."),
                actionButton("sl_submit","Save Count",class="btn-success",icon=icon("hashtag")),
                br(),br(),textOutput("sl_feedback"),
                hr(),h4("Sowing event"),
                tags$p(tags$em("Record treatments, pathogens, or cultivation events.",
                  style="color:#666;font-size:13px;")),
                dateInput("se_date","Date",value=Sys.Date()),
                selectInput("se_type","Event type",
                  choices=c("fungicide treatment","pesticide treatment",
                            "heat treatment","pathogen observed - fungus",
                            "pathogen observed - rot","pathogen observed - other",
                            "thinned","first watering","other")),
                textAreaInput("se_notes","Notes",rows=3,
                  placeholder="product used, concentration, affected seedlings..."),
                actionButton("se_submit","Save Event",
                  class="btn-warning",icon=icon("triangle-exclamation")),
                br(),br(),textOutput("se_feedback")
              ),
              column(7,
                h4("Count history"),DTOutput("sl_history"),
                br(),
                actionButton("sl_edit_btn","Edit selected count",
                  class="btn-sm btn-default",icon=icon("pen")),
                actionButton("sl_del_btn","Delete selected count",
                  class="btn-sm btn-danger",icon=icon("trash"),style="margin-left:6px;"),
                br(),br(),h4("Event history"),DTOutput("se_history")
              )
            )
          ),

          tabPanel(title=tagList(icon("chart-line")," Survival Chart"),
            fluidRow(
              column(4,
                selectInput("sc_sowing","Sowing",choices=NULL),
                checkboxInput("sc_pct","Show as % of seeds sown",value=FALSE),
                checkboxInput("sc_events","Overlay sowing events",value=TRUE),
                hr(),verbatimTextOutput("sc_summary")
              ),
              column(8,plotOutput("survival_plot",height="420px"))
            )
          ),

          tabPanel(title=tagList(icon("arrow-up")," Graduate to Plant"),
            fluidRow(
              column(6,
                h4("Promote a seedling to a tracked plant"),
                tags$p("When a seedling is large enough to track individually,",
                  " create a plant record linked to its sowing history.",
                  style="color:#555;font-size:13px;"),
                selectInput("gr_sowing","Sowing to graduate from *",choices=NULL),
                uiOutput("gr_sowing_info"),
                hr(),
                textInput("gr_cultivar","Cultivar / form (if known)",placeholder="optional"),
                textInput("gr_common","Common name",placeholder="optional"),
                dateInput("gr_date","Date (when potted up individually)",value=Sys.Date()),
                textAreaInput("gr_notes","Notes",rows=2,
                  placeholder="which seedling, pot size, initial condition..."),
                actionButton("gr_submit","Create Plant Record",
                  class="btn-success btn-lg",icon=icon("seedling")),
                br(),br(),uiOutput("gr_feedback_ui")
              ),
              column(6,h4("Plants already graduated"),DTOutput("graduated_plants"))
            )
          )
        ))
      ),

      # ══ TOOLS ════════════════════════════════════════════════════════════════
      tabItem(tabName="tools",
        fluidRow(tabBox(width=12,id="tools_tabs",

          # ── Labels ──────────────────────────────────────────────────────────
          tabPanel(title=tagList(icon("tag")," Labels"),
            fluidRow(
              column(4,
                h4("Label settings"),
                fluidRow(
                  column(6,numericInput("lbl_w","Width (mm)",value=55,min=10,max=200,step=1)),
                  column(6,numericInput("lbl_h","Height (mm)",value=19,min=10,max=200,step=1))
                ),
                numericInput("lbl_font","Font size (pt)",value=7,min=5,max=20,step=1),
                checkboxInput("lbl_border","Show label border",value=TRUE),
                hr(),
                h4("Fields to include"),
                checkboxGroupInput("lbl_fields","",
                  choices=c(
                    "Genus / species"="genus_species",
                    "Family"="family",
                    "Common name"="common_name",
                    "Geographic origin"="origin_geo",
                    "Native substrate"="origin_soil",
                    "Date acquired"="acquired",
                    "Source"="source",
                    "Supplier"="supplier",
                    "Dormancy"="dormancy",
                    "Toxicity"="toxicity",
                    "Notes"="notes",
                    "Llifle URL"="llifle_url"
                  ),
                  selected=c("genus_species","origin_geo","acquired")
                ),
                hr(),
                h4("Which plants?"),
                radioButtons("lbl_scope","",
                  choices=c("All active plants"="all",
                            "Selected plant only"="selected"),
                  selected="all"),
                conditionalPanel("input.lbl_scope == 'selected'",
                  selectInput("lbl_plant","Plant",choices=NULL)
                ),
                br(),
                downloadButton("lbl_download","Download label sheet",
                  class="btn-success")
              ),
              column(8,
                h4("Preview (first label)"),
                uiOutput("lbl_preview"),
                br(),
                tags$p(tags$em(
                  "Download opens an HTML file. Open in your browser and use File > Print.",
                  " Set paper size to match your label dimensions.",
                  style="color:#666;font-size:13px;"))
              )
            )
          ),

          # ── Export ──────────────────────────────────────────────────────────
          tabPanel(title=tagList(icon("file-excel")," Export"),
            fluidRow(
              column(6,
                h4("Export to Excel"),
                tags$p("Each selected table is written to a separate sheet in one workbook.",
                  style="color:#555;"),
                checkboxGroupInput("exp_tables","Include tables:",
                  choices=c(
                    "Plants (full details)"="plants",
                    "Measurements"="measurements",
                    "Events & notes"="events",
                    "Flowering records"="flowering",
                    "Soil mixes"="soil_mixes",
                    "Sowings"="sowings",
                    "Seedling counts"="seedling_counts",
                    "Sowing events"="sowing_events"
                  ),
                  selected=c("plants","measurements","events","flowering")
                ),
                hr(),
                selectInput("exp_status","Plant status filter",
                  choices=c("Active only"="active","All plants"="all"),
                  selected="active"),
                br(),
                downloadButton("exp_download","Download Excel workbook",
                  class="btn-success"),
                br(),br(),
                tags$p(tags$em("Requires the openxlsx package.",
                  style="color:#888;font-size:12px;"))
              )
            )
          ),

          # ── Import ──────────────────────────────────────────────────────────
          tabPanel(title=tagList(icon("file-import")," Import"),
            fluidRow(
              column(5,
                h4("Import plants from CSV or Excel"),
                tags$p("Upload a CSV or XLSX file, then map its columns to database fields.",
                  style="color:#555;"),
                fileInput("imp_file","Choose file",
                  accept=c(".csv",".xlsx",".xls"),
                  buttonLabel="Browse..."),
                uiOutput("imp_mapping_ui"),
                br(),
                conditionalPanel("output.imp_ready",
                  actionButton("imp_submit","Import plants",
                    class="btn-success btn-lg",icon=icon("file-import")),
                  br(),br(),
                  uiOutput("imp_feedback_ui")
                )
              ),
              column(7,
                h4("File preview (first 6 rows)"),
                DTOutput("imp_preview")
              )
            )
          )
        ))
      )

      ,

      # ══ GALLERY ══════════════════════════════════════════════════════════════
      tabItem(tabName="gallery",
        tags$div(
          fluidRow(
            box(width=12, title="Photo Gallery", status="success", solidHeader=TRUE,
              fluidRow(class="gallery-filter",
                column(3, selectInput("gal_family","Family",
                  choices=c("All families"=""), width="100%")),
                column(3, selectInput("gal_genus","Genus",
                  choices=c("All genera"=""), width="100%")),
                column(3, textInput("gal_search","Search species / caption",
                  placeholder="type to filter...")),
                column(3, br(),
                  checkboxInput("gal_unphoto","Show plants with no photos",value=FALSE))
              ),
              uiOutput("gallery_ui")
            )
          )
        )
      )

    ) # end tabItems
  )
)


# ══════════════════════════════════════════════════════════════════════════════
# SERVER
# ══════════════════════════════════════════════════════════════════════════════
server <- function(input, output, session) {

  refresh <- reactiveVal(0)
  bump    <- function() refresh(refresh() + 1)

  # ── Shared dropdowns ────────────────────────────────────────────────────────
  plant_choices <- reactive({
    refresh()
    con <- get_con(); on.exit(dbDisconnect(con))
    df  <- dbGetQuery(con,
      "SELECT id,genus,species,cultivar FROM plants WHERE status='active' ORDER BY genus,species")
    if (nrow(df)==0) return(c("No active plants"=""))
    setNames(as.character(df$id), plant_label(df))
  })

  sowing_choices <- reactive({
    refresh()
    con <- get_con(); on.exit(dbDisconnect(con))
    df  <- dbGetQuery(con, "SELECT id,genus,species,sow_date FROM sowings ORDER BY sow_date DESC")
    if (nrow(df)==0) return(c("No sowings yet"=""))
    setNames(as.character(df$id), sowing_label(df))
  })

  observe({
    ch <- plant_choices()
    for (id in c("m_plant","fl_plant","sm_plant","ph_plant","e_plant","ch_plant","lbl_plant"))
      updateSelectInput(session, id, choices=ch)
    updateSelectInput(session, "ph_filter", choices=c("All"="", ch))
    updateSelectInput(session, "e_filter_plant", choices=c("All"="", ch))
  })

  observe({
    ch <- sowing_choices()
    for (id in c("sl_sowing","sc_sowing","gr_sowing"))
      updateSelectInput(session, id, choices=ch)
    updateSelectInput(session, "ap_sowing", choices=c("None"="", ch))
  })

  observe({
    refresh()
    con <- get_con(); on.exit(dbDisconnect(con))
    # Client-side selectize: no server=TRUE so create=TRUE and empty default work correctly
    updateSelectizeInput(session,"ap_family",
      choices  = c("", distinct_vals(con,"plants","family")),
      selected = "",
      options  = list(create=TRUE, placeholder="e.g. Cactaceae"))
    updateSelectizeInput(session,"ap_origin_geo",
      choices  = c("", distinct_vals(con,"plants","origin_geo")),
      selected = "",
      options  = list(create=TRUE, placeholder="e.g. Andean foothills, Peru"))
    updateSelectizeInput(session,"ap_origin_soil",
      choices  = c("", distinct_vals(con,"plants","origin_soil")),
      selected = "",
      options  = list(create=TRUE, placeholder="e.g. limestone scree"))
    updateSelectizeInput(session,"fl_colour",
      choices  = c("", distinct_vals(con,"flowering","flower_colour")),
      selected = "",
      options  = list(create=TRUE, placeholder="e.g. cerise pink with white throat"))
    updateSelectizeInput(session,"sw_origin",
      choices  = c("", distinct_vals(con,"sowings","seed_origin")),
      selected = "",
      options  = list(create=TRUE, placeholder="e.g. Mesa Garden, own harvest 2023..."))
  })


  # ════════════════════════════════════════════════════════════════════════════
  # COLLECTION
  # ════════════════════════════════════════════════════════════════════════════
  filtered_plants <- reactive({
    refresh()
    con <- get_con(); on.exit(dbDisconnect(con))
    q <- "SELECT id,family,genus,species,cultivar,common_name,source,acquired,dormancy,status,sowing_id FROM plants WHERE 1=1"
    if (input$col_status!="All") q <- paste0(q,sprintf(" AND status='%s'",input$col_status))
    s <- trimws(input$col_search %||% "")
    if (nchar(s)>0) {
      safe <- gsub("'","''",s)
      q <- paste0(q,sprintf(" AND (genus LIKE '%%%1$s%%' OR species LIKE '%%%1$s%%' OR family LIKE '%%%1$s%%' OR common_name LIKE '%%%1$s%%')",safe))
    }
    dbGetQuery(con, paste0(q," ORDER BY genus,species"))
  })

  output$collection_table <- renderDT({
    df <- filtered_plants()
    df$dormancy <- dplyr::recode(df$dormancy %||% "none",
      "summer"="☀ Summer","winter"="❄ Winter","none"="—",.default="—")
    df$sowing_id <- ifelse(!is.na(df$sowing_id),"🌱","")
    con <- get_con(); on.exit(dbDisconnect(con))
    thumbs <- dbGetQuery(con,
      "SELECT plant_id, file_name FROM photos p1
       WHERE photo_date = (SELECT MAX(photo_date) FROM photos p2 WHERE p2.plant_id=p1.plant_id)
       GROUP BY plant_id")
    thumb_map <- setNames(thumbs$file_name, as.character(thumbs$plant_id))
    df$photo <- ifelse(
      as.character(df$id) %in% names(thumb_map),
      paste0('<img src="photos/', thumb_map[as.character(df$id)],
             '" style="height:40px;width:40px;object-fit:cover;border-radius:4px;border:1px solid #ddd;" ',
             'onerror="this.style.display:none">'),
      "")
    df <- df[, c("photo", setdiff(names(df), "photo"))]
    datatable(df, selection="multiple", rownames=FALSE, escape=FALSE,
              options=list(pageLength=15, scrollX=TRUE, stateSave=TRUE,
                columnDefs=list(list(orderable=FALSE, targets=0),
                                list(width="50px", targets=0))))
  })

  selected_plant_id <- reactive({
    rows <- input$collection_table_rows_selected
    if (length(rows)==0) return(NULL)
    df <- filtered_plants()
    rows <- rows[rows <= nrow(df)]
    if (length(rows)==0) return(NULL)
    df$id[rows]
  })

  # Count label for selected rows
  output$col_sel_count <- renderText({
    n <- length(input$collection_table_rows_selected)
    if (n == 0) "" else paste0(n, " selected")
  })

  # Detail panel
  output$plant_detail_panel <- renderUI({
    pid <- selected_plant_id(); if (is.null(pid)) return(NULL)
    con <- get_con(); on.exit(dbDisconnect(con))
    p   <- dbGetQuery(con, sprintf("SELECT * FROM plants WHERE id=%d",pid))
    if (nrow(p)==0) return(NULL)

    photos   <- dbGetQuery(con,sprintf("SELECT file_name,photo_date,caption FROM photos WHERE plant_id=%d ORDER BY photo_date DESC",pid))
    last_mix <- dbGetQuery(con,sprintf("SELECT id,date_set FROM soil_mixes WHERE plant_id=%d ORDER BY date_set DESC LIMIT 1",pid))
    mix_str  <- "\u2014"
    if (nrow(last_mix)>0) {
      comps <- dbGetQuery(con,sprintf("SELECT component,percentage FROM soil_mix_components WHERE mix_id=%d ORDER BY percentage DESC",last_mix$id))
      if (nrow(comps)>0) {
        mix_str <- paste(apply(comps,1,function(r){
          pct <- suppressWarnings(as.numeric(r["percentage"]))
          if(!is.na(pct)) paste0(r["component"],"\u202f",pct,"%") else r["component"]
        }),collapse=", ")
        mix_str <- paste0(mix_str," (",last_mix$date_set,")")
      }
    }
    sow_str <- NULL
    if (!is.null(p$sowing_id) && !is.na(p$sowing_id)) {
      sw <- dbGetQuery(con,sprintf("SELECT genus,species,sow_date,seed_origin,date_first_germ FROM sowings WHERE id=%d",p$sowing_id))
      if (nrow(sw)>0) sow_str <- paste0(sw$genus," ",sw$species %||% ""," sown ",sw$sow_date,
        if(!is.na(sw$seed_origin)&&sw$seed_origin!="") paste0(" (",sw$seed_origin,")") else "")
    }
    llifle_url <- p$llifle_url %||% LLIFLE_BASE
    dorm_el <- switch(p$dormancy %||% "none",
      summer=tags$span("\u2600 Summer dormant",class="dorm-badge dorm-summer"),
      winter=tags$span("\u2744 Winter dormant",class="dorm-badge dorm-winter"),
      tags$span("\u2014"))
    title_str <- trimws(paste(p$genus,
      if(!is.na(p$species)&&p$species!="") p$species else "",
      if(!is.na(p$cultivar)&&p$cultivar!="") paste0("'",p$cultivar,"'") else ""))

    fluidRow(box(width=12,title=title_str,status="success",collapsible=TRUE,
      # Action buttons row
      fluidRow(column(12,
        actionButton("plant_edit_btn","Edit plant",class="btn-sm btn-primary",icon=icon("pen")),
        actionButton("plant_dup_btn","Duplicate",class="btn-sm btn-default",
          icon=icon("copy"),style="margin-left:6px;"),
        style="margin-bottom:10px;"
      )),
      fluidRow(
        column(4,
          tags$p(tags$span("Family:",class="detail-label"),p$family %||% "\u2014"),
          tags$p(tags$span("Common name:",class="detail-label"),p$common_name %||% "\u2014"),
          tags$p(tags$span("Source:",class="detail-label"),p$source %||% "\u2014"),
          tags$p(tags$span("Supplier / from:",class="detail-label"),p$supplier %||% "\u2014"),
          tags$p(tags$span("Acquired:",class="detail-label"),p$acquired %||% "\u2014"),
          tags$p(tags$span("Status:",class="detail-label"),p$status %||% "\u2014"),
          if(!is.null(sow_str)) tags$p(tags$span("Sowing provenance:",class="detail-label"),
            tags$span(sow_str,class="seed-badge")) else NULL
        ),
        column(4,
          tags$p(tags$span("Dormancy:",class="detail-label"),dorm_el),
          tags$p(tags$span("Geographic origin:",class="detail-label"),p$origin_geo %||% "\u2014"),
          tags$p(tags$span("Native substrate:",class="detail-label"),p$origin_soil %||% "\u2014"),
          tags$p(tags$span("Toxicity:",class="detail-label"),p$toxicity %||% "\u2014"),
          tags$p(tags$span("Current soil mix:",class="detail-label"),mix_str),
          tags$p(tags$span("Llifle:",class="detail-label"),
            tags$a("View species page \u2197",href=llifle_url,target="_blank",class="llifle-link"))
        ),
        column(4,
          tags$p(tags$span("Notes:",class="detail-label")),
          tags$p(style="white-space:pre-wrap;",p$notes %||% "\u2014")
        )
      ),
      if(nrow(photos)>0) tagList(hr(),
        tags$p(tags$span(paste0("Photos (",nrow(photos),"):"),class="detail-label")),
        tags$div(lapply(seq_len(min(nrow(photos),10)),function(i){
          fname <- photos$file_name[i]; cap <- photos$caption[i] %||% photos$photo_date[i]
          tags$div(style="display:inline-block;text-align:center;vertical-align:top;margin:4px;",
            tags$a(href=paste0("photos/",fname),target="_blank",
              tags$img(src=paste0("photos/",fname),class="photo-thumb",title=cap,alt=cap)),
            tags$br(),tags$small(photos$photo_date[i],style="color:#777;"))
        }))
      ) else NULL
    ))
  })

  # Archive
  observeEvent(input$col_delete_btn,{
    pids <- selected_plant_id(); req(!is.null(pids))
    n   <- length(pids)
    con <- get_con(); on.exit(dbDisconnect(con))
    label <- if (n == 1) {
      pl <- dbGetQuery(con, sprintf("SELECT genus,species FROM plants WHERE id=%d", pids))
      trimws(paste(pl$genus, pl$species %||% ""))
    } else paste0(n, " plants")
    showModal(modalDialog(title="Archive plants",
      tags$p("Move ", tags$strong(label), " to the archive?"),
      tags$p(tags$em("All associated records (measurements, events, photos etc.) are kept.")),
      footer=tagList(modalButton("Cancel"),
        actionButton("confirm_delete","Archive",class="btn-warning"))))
  })
  observeEvent(input$confirm_delete,{
    pids <- selected_plant_id(); req(!is.null(pids))
    con  <- get_con(); on.exit(dbDisconnect(con))
    placeholders <- paste(rep("?", length(pids)), collapse=",")
    dbExecute(con,
      paste0("UPDATE plants SET status='archived' WHERE id IN (", placeholders, ")"),
      as.list(pids))
    removeModal(); bump()
  })

  # Hard delete — permanently removes plant and all linked records
  observeEvent(input$col_hard_delete_btn,{
    pids <- selected_plant_id(); req(!is.null(pids))
    n   <- length(pids)
    con <- get_con(); on.exit(dbDisconnect(con))
    label <- if (n == 1) {
      pl <- dbGetQuery(con, sprintf("SELECT genus,species FROM plants WHERE id=%d", pids))
      trimws(paste(pl$genus, pl$species %||% ""))
    } else paste0(n, " plants")
    showModal(modalDialog(title="Permanently delete plants",
      tags$div(class="alert alert-danger",style="margin:0;",
        tags$strong("This cannot be undone."),
        tags$br(),
        paste0("All records for ", label,
               " will be permanently deleted: measurements, events, ",
               "flowering records, soil mixes, and photos.")),
      footer=tagList(modalButton("Cancel"),
        actionButton("confirm_hard_delete","Delete permanently",class="btn-danger"))))
  })
  observeEvent(input$confirm_hard_delete,{
    pids <- selected_plant_id(); req(!is.null(pids))
    con  <- get_con(); on.exit(dbDisconnect(con))
    ph   <- paste(rep("?", length(pids)), collapse=",")
    # Delete all linked records first, then the plant rows
    for (tbl in c("measurements","events","flowering","soil_mixes","photos"))
      dbExecute(con,
        paste0("DELETE FROM ", tbl, " WHERE plant_id IN (", ph, ")"),
        as.list(pids))
    # soil_mix_components cascade via mix_id — clean up orphans
    dbExecute(con,
      "DELETE FROM soil_mix_components WHERE mix_id NOT IN (SELECT id FROM soil_mixes)")
    dbExecute(con,
      paste0("DELETE FROM plants WHERE id IN (", ph, ")"),
      as.list(pids))
    removeModal(); bump()
  })


  # ── EDIT PLANT modal ────────────────────────────────────────────────────────
  observeEvent(input$plant_edit_btn,{
    pid <- selected_plant_id(); req(!is.null(pid))
    con <- get_con(); on.exit(dbDisconnect(con))
    p   <- dbGetQuery(con,sprintf("SELECT * FROM plants WHERE id=%d",pid))
    req(nrow(p)>0)
    showModal(modalDialog(title=paste("Edit plant:",p$genus,p$species %||% ""),
      size="l",easyClose=TRUE,
      fluidRow(
        column(6,
          textInput("ep_genus","Genus *",value=na_str(p$genus)),
          textInput("ep_species","Species",value=na_str(p$species)),
          textInput("ep_cultivar","Cultivar",value=na_str(p$cultivar)),
          textInput("ep_common","Common name",value=na_str(p$common_name)),
          textInput("ep_family","Family",value=na_str(p$family)),
          selectInput("ep_source","Source",
            choices=c("purchase","seed","cutting","offset","gift","other"),
            selected=na_str(p$source)),
          textInput("ep_supplier","Supplier",value=na_str(p$supplier)),
          textInput("ep_acquired","Date acquired (YYYY-MM-DD)",value=na_str(p$acquired))
        ),
        column(6,
          textInput("ep_origin_geo","Geographic origin",value=na_str(p$origin_geo)),
          textInput("ep_origin_soil","Native substrate",value=na_str(p$origin_soil)),
          selectInput("ep_dormancy","Dormancy",
            choices=c("None"="none","Summer dormant"="summer","Winter dormant"="winter"),
            selected=p$dormancy %||% "none"),
          selectInput("ep_status","Status",
            choices=c("active","archived","deceased","gifted"),
            selected=p$status %||% "active"),
          textInput("ep_llifle","Llifle URL",value=na_str(p$llifle_url)),
          textAreaInput("ep_toxicity","Toxicity",value=na_str(p$toxicity),rows=2),
          textAreaInput("ep_notes","Notes",value=na_str(p$notes),rows=3)
        )
      ),
      footer=tagList(modalButton("Cancel"),
        actionButton("ep_save","Save changes",class="btn-primary")),
      tags$input(type="hidden",id="ep_plant_id",value=pid)
    ))
  })

  # Store genus/family from the edit modal so the family-propagation
  # observer can access them after the modal closes
  ep_pending <- reactiveValues(genus = NULL, family = NULL)

  observeEvent(input$ep_save,{
    pid <- selected_plant_id(); req(!is.null(pid))
    req(nchar(trimws(input$ep_genus))>0)
    genus  <- trimws(input$ep_genus)
    family <- trimws(input$ep_family)
    con <- get_con(); on.exit(dbDisconnect(con))
    dbExecute(con,"UPDATE plants SET genus=?,species=?,cultivar=?,common_name=?,family=?,
      source=?,supplier=?,acquired=?,origin_geo=?,origin_soil=?,dormancy=?,status=?,
      llifle_url=?,toxicity=?,notes=? WHERE id=?",
      list(genus,trimws(input$ep_species),trimws(input$ep_cultivar),
           trimws(input$ep_common),family,input$ep_source,
           trimws(input$ep_supplier),trimws(input$ep_acquired),
           trimws(input$ep_origin_geo),trimws(input$ep_origin_soil),
           input$ep_dormancy,input$ep_status,
           trimws(input$ep_llifle),trimws(input$ep_toxicity),trimws(input$ep_notes),pid))
    removeModal()
    bump()

    # Check for other plants of the same genus missing this family
    if (nchar(family) > 0) {
      others <- dbGetQuery(con,
        "SELECT id FROM plants WHERE genus = ? AND (family IS NULL OR family = '' OR family != ?) AND id != ?",
        list(genus, family, pid))
      if (nrow(others) > 0) {
        ep_pending$genus  <- genus
        ep_pending$family <- family
        showModal(modalDialog(
          title = paste0("Update family for all ", genus, "?"),
          tags$p(
            "You set the family to ", tags$strong(family), " for this ", tags$em(genus), ".",
            tags$br(), tags$br(),
            "There ", if (nrow(others) == 1) "is" else "are",
            tags$strong(paste0(" ", nrow(others), " other ")),
            if (nrow(others) == 1) paste0(genus, " record") else paste0(genus, " records"),
            " with a missing or different family name.",
            tags$br(), tags$br(),
            "Would you like to set all of them to ", tags$strong(family), " as well?"
          ),
          footer = tagList(
            modalButton("No, leave them"),
            actionButton("ep_family_propagate", "Yes, update all",
                         class = "btn-success")
          )
        ))
      }
    }
  })

  observeEvent(input$ep_family_propagate, {
    genus  <- ep_pending$genus
    family <- ep_pending$family
    req(!is.null(genus), !is.null(family))
    con <- get_con(); on.exit(dbDisconnect(con))
    dbExecute(con,
      "UPDATE plants SET family = ? WHERE genus = ? AND (family IS NULL OR family = '' OR family != ?)",
      list(family, genus, family))
    removeModal()
    ep_pending$genus  <- NULL
    ep_pending$family <- NULL
    bump()
  })


  # ── DUPLICATE plant ─────────────────────────────────────────────────────────
  observeEvent(input$plant_dup_btn,{
    pid <- selected_plant_id(); req(!is.null(pid))
    con <- get_con(); on.exit(dbDisconnect(con))
    p   <- dbGetQuery(con,sprintf("SELECT * FROM plants WHERE id=%d",pid))
    req(nrow(p)>0)
    # Switch to Add Plant tab and pre-fill fields
    updateTabItems(session,"sidebar","add_plant")
    output$ap_prefill_banner <- renderUI(
      tags$div(class="alert alert-info",style="margin-bottom:10px;",
        tags$strong("Duplicated from: "),p$genus," ",p$species %||% "",
        " — edit as needed and click Add Plant to save as a new record."))
    updateTextInput(session,"ap_genus",   value=na_str(p$genus))
    updateTextInput(session,"ap_species", value=na_str(p$species))
    updateTextInput(session,"ap_cultivar",value=na_str(p$cultivar))
    updateTextInput(session,"ap_common",  value=na_str(p$common_name))
    updateTextInput(session,"ap_supplier",value=na_str(p$supplier))
    updateTextInput(session,"ap_llifle",  value=na_str(p$llifle_url))
    updateSelectInput(session,"ap_source",   selected=p$source %||% "purchase")
    updateSelectInput(session,"ap_dormancy", selected=p$dormancy %||% "none")
    updateTextAreaInput(session,"ap_toxicity",value=na_str(p$toxicity))
    updateTextAreaInput(session,"ap_notes",   value=na_str(p$notes))
  })


  # ════════════════════════════════════════════════════════════════════════════
  # ADD PLANT
  # ════════════════════════════════════════════════════════════════════════════
  output$ap_prefill_banner <- renderUI(NULL)

  # Auto-fill family when genus is typed, if that genus already has a known family.
  # Always overwrites whatever is in the family field so stale values from a
  # previous entry are corrected automatically. If the genus is unknown, the
  # field is left as-is so manually typed families are not wiped.
  observeEvent(input$ap_genus, {
    genus <- trimws(input$ap_genus %||% "")
    if (nchar(genus) == 0) return()
    con <- get_con(); on.exit(dbDisconnect(con))
    known <- dbGetQuery(con,
      "SELECT family FROM plants WHERE genus = ? COLLATE NOCASE AND family IS NOT NULL AND family != '' LIMIT 1",
      list(genus))
    if (nrow(known) > 0) {
      updateSelectizeInput(session, "ap_family",
        choices  = c("", distinct_vals(con, "plants", "family")),
        selected = known$family[1],
        options  = list(create = TRUE, placeholder = "e.g. Cactaceae"))
    }
  }, ignoreInit = TRUE)

  observeEvent(input$ap_submit,{
    req(nchar(trimws(input$ap_genus))>0)
    con <- get_con(); on.exit(dbDisconnect(con))
    llifle  <- trimws(input$ap_llifle %||% "")
    if(llifle==LLIFLE_BASE||llifle=="") llifle <- NA_character_
    sow_id  <- if(!is.null(input$ap_sowing)&&input$ap_sowing!="") as.integer(input$ap_sowing) else NA_integer_
    dbExecute(con,"INSERT INTO plants (genus,species,cultivar,common_name,family,source,supplier,acquired,origin_geo,origin_soil,dormancy,llifle_url,toxicity,notes,sowing_id) VALUES (?,?,?,?,?,?,?,?,?,?,?,?,?,?,?)",
      list(trimws(input$ap_genus),trimws(input$ap_species %||% ""),trimws(input$ap_cultivar %||% ""),
           trimws(input$ap_common %||% ""),trimws(input$ap_family %||% ""),input$ap_source,
           trimws(input$ap_supplier %||% ""),as.character(input$ap_acquired),
           trimws(input$ap_origin_geo %||% ""),trimws(input$ap_origin_soil %||% ""),
           input$ap_dormancy,llifle,trimws(input$ap_toxicity %||% ""),trimws(input$ap_notes %||% ""),sow_id))
    output$ap_feedback_ui <- renderUI(tags$p("\u2713 Plant added.",style="color:#2e7d32;font-weight:bold;"))
    output$ap_prefill_banner <- renderUI(NULL)
    bump()
    for(id in c("ap_genus","ap_species","ap_cultivar","ap_common","ap_supplier","ap_llifle"))
      updateTextInput(session,id,value="")
    for(id in c("ap_toxicity","ap_notes")) updateTextAreaInput(session,id,value="")
    updateSelectInput(session,"ap_dormancy",selected="none")
    updateSelectInput(session,"ap_sowing",selected="")
    updateSelectizeInput(session,"ap_family",     selected="", options=list(create=TRUE))
    updateSelectizeInput(session,"ap_origin_geo",  selected="", options=list(create=TRUE))
    updateSelectizeInput(session,"ap_origin_soil", selected="", options=list(create=TRUE))
  })

  output$quick_stats <- renderText({
    refresh(); con <- get_con(); on.exit(dbDisconnect(con))
    n <- function(q) dbGetQuery(con,q)$n
    paste0("Active plants:      ",n("SELECT COUNT(*) AS n FROM plants WHERE status='active'"),"\n",
           "Total plants:       ",n("SELECT COUNT(*) AS n FROM plants"),"\n",
           "Sowings:            ",n("SELECT COUNT(*) AS n FROM sowings"),"\n",
           "Measurements:       ",n("SELECT COUNT(*) AS n FROM measurements"),"\n",
           "Flowering records:  ",n("SELECT COUNT(*) AS n FROM flowering"),"\n",
           "Photos:             ",n("SELECT COUNT(*) AS n FROM photos"),"\n",
           "Event records:      ",n("SELECT COUNT(*) AS n FROM events"))
  })


  # ════════════════════════════════════════════════════════════════════════════
  # RECORD > MEASUREMENTS (save + edit + delete)
  # ════════════════════════════════════════════════════════════════════════════
  observeEvent(input$m_submit,{
    req(input$m_plant!=""); con <- get_con(); on.exit(dbDisconnect(con))
    dbExecute(con,"INSERT INTO measurements (plant_id,meas_date,height_mm,width_mm,offsets,notes) VALUES (?,?,?,?,?,?)",
      list(as.integer(input$m_plant),as.character(input$m_date),
           if(is.na(input$m_height)) NA_real_ else input$m_height,
           if(is.na(input$m_width))  NA_real_ else input$m_width,
           if(is.na(input$m_offsets)) NA_integer_ else as.integer(input$m_offsets),
           trimws(input$m_notes %||% "")))
    output$m_feedback <- renderText("\u2713 Measurement saved."); bump()
  })

  output$recent_measurements <- renderDT({
    refresh(); con <- get_con(); on.exit(dbDisconnect(con))
    df <- dbGetQuery(con,"SELECT m.id,p.genus,p.species,m.meas_date AS date,m.height_mm,m.width_mm,m.offsets,m.notes FROM measurements m JOIN plants p ON m.plant_id=p.id ORDER BY m.meas_date DESC LIMIT 100")
    datatable(df,selection="single",rownames=FALSE,options=list(pageLength=10,scrollX=TRUE))
  })

  observeEvent(input$m_edit_btn,{
    rows <- input$recent_measurements_rows_selected; req(length(rows)>0)
    con <- get_con(); on.exit(dbDisconnect(con))
    df  <- dbGetQuery(con,"SELECT m.id,m.meas_date,m.height_mm,m.width_mm,m.offsets,m.notes FROM measurements m JOIN plants p ON m.plant_id=p.id ORDER BY m.meas_date DESC LIMIT 100")
    req(rows<=nrow(df)); r <- df[rows,]
    showModal(modalDialog(title="Edit measurement",easyClose=TRUE,
      textInput("em_date","Date (YYYY-MM-DD)",value=na_str(r$meas_date)),
      numericInput("em_height","Height (mm)",value=r$height_mm,min=0),
      numericInput("em_width","Width (mm)",value=r$width_mm,min=0),
      numericInput("em_offsets","Offsets / heads",value=r$offsets,min=0),
      textAreaInput("em_notes","Notes",value=na_str(r$notes),rows=2),
      tags$input(type="hidden",id="em_id",value=r$id),
      footer=tagList(modalButton("Cancel"),actionButton("em_save","Save",class="btn-primary"))))
  })
  observeEvent(input$em_save,{
    rows <- input$recent_measurements_rows_selected; req(length(rows)>0)
    con <- get_con(); on.exit(dbDisconnect(con))
    df  <- dbGetQuery(con,"SELECT id FROM measurements ORDER BY meas_date DESC LIMIT 100")
    req(rows<=nrow(df)); mid <- df$id[rows]
    dbExecute(con,"UPDATE measurements SET meas_date=?,height_mm=?,width_mm=?,offsets=?,notes=? WHERE id=?",
      list(trimws(input$em_date),
           if(is.na(input$em_height)) NA_real_ else input$em_height,
           if(is.na(input$em_width))  NA_real_ else input$em_width,
           if(is.na(input$em_offsets)) NA_integer_ else as.integer(input$em_offsets),
           trimws(input$em_notes),mid))
    removeModal(); bump()
  })
  observeEvent(input$m_del_btn,{
    rows <- input$recent_measurements_rows_selected; req(length(rows)>0)
    con <- get_con(); on.exit(dbDisconnect(con))
    df  <- dbGetQuery(con,"SELECT id FROM measurements ORDER BY meas_date DESC LIMIT 100")
    req(rows<=nrow(df)); mid <- df$id[rows]
    dbExecute(con,"DELETE FROM measurements WHERE id=?",list(mid))
    bump()
  })


  # ════════════════════════════════════════════════════════════════════════════
  # RECORD > FLOWERING (save + edit + delete)
  # ════════════════════════════════════════════════════════════════════════════
  observeEvent(input$fl_submit,{
    req(input$fl_plant!=""); con <- get_con(); on.exit(dbDisconnect(con))
    dbExecute(con,"INSERT INTO flowering (plant_id,start_date,end_date,flower_colour,pollination_notes,seeds_set,seed_notes,notes) VALUES (?,?,?,?,?,?,?,?)",
      list(as.integer(input$fl_plant),as.character(input$fl_start),as.character(input$fl_end),
           trimws(input$fl_colour %||% ""),trimws(input$fl_pollination %||% ""),
           as.integer(isTRUE(input$fl_seeds)),trimws(input$fl_seed_notes %||% ""),trimws(input$fl_notes %||% "")))
    fl_id <- dbGetQuery(con,"SELECT last_insert_rowid() AS id")$id
    photo_info <- input$fl_photo
    if(!is.null(photo_info)&&nrow(photo_info)>0){
      ext      <- tolower(file_ext(photo_info$name))
      new_name <- sprintf("p%s_fl%d_%s.%s",input$fl_plant,fl_id,format(Sys.time(),"%Y%m%d%H%M%S"),ext)
      file.copy(photo_info$datapath,file.path(PHOTO_DIR,new_name))
      dbExecute(con,"INSERT INTO photos (plant_id,photo_date,file_name,caption,flowering_id) VALUES (?,?,?,?,?)",
        list(as.integer(input$fl_plant),as.character(input$fl_start),new_name,trimws(input$fl_photo_caption %||% ""),fl_id))
    }
    output$fl_feedback <- renderText("\u2713 Flowering record saved."); bump()
  })

  output$flowering_history <- renderDT({
    refresh(); con <- get_con(); on.exit(dbDisconnect(con))
    df <- dbGetQuery(con,"SELECT f.id,p.genus,p.species,f.start_date,f.end_date,f.flower_colour,f.seeds_set,f.pollination_notes FROM flowering f JOIN plants p ON f.plant_id=p.id ORDER BY f.start_date DESC")
    df$seeds_set <- ifelse(df$seeds_set==1L,"Yes","No")
    datatable(df,selection="single",rownames=FALSE,options=list(pageLength=10,scrollX=TRUE))
  })

  observeEvent(input$fl_edit_btn,{
    rows <- input$flowering_history_rows_selected; req(length(rows)>0)
    con <- get_con(); on.exit(dbDisconnect(con))
    df  <- dbGetQuery(con,"SELECT f.* FROM flowering f JOIN plants p ON f.plant_id=p.id ORDER BY f.start_date DESC")
    req(rows<=nrow(df)); r <- df[rows,]
    showModal(modalDialog(title="Edit flowering record",easyClose=TRUE,size="m",
      fluidRow(
        column(6,textInput("efl_start","Start date",value=na_str(r$start_date)),
               textInput("efl_end","End date",value=na_str(r$end_date)),
               textInput("efl_colour","Flower colour",value=na_str(r$flower_colour))),
        column(6,textAreaInput("efl_pollination","Pollination notes",value=na_str(r$pollination_notes),rows=2),
               checkboxInput("efl_seeds","Seeds set",value=isTRUE(r$seeds_set==1L)),
               textAreaInput("efl_seed_notes","Seed notes",value=na_str(r$seed_notes),rows=2))
      ),
      textAreaInput("efl_notes","Other notes",value=na_str(r$notes),rows=2),
      footer=tagList(modalButton("Cancel"),actionButton("efl_save","Save",class="btn-primary")),
      tags$input(type="hidden",id="efl_id",value=r$id)
    ))
  })
  observeEvent(input$efl_save,{
    rows <- input$flowering_history_rows_selected; req(length(rows)>0)
    con <- get_con(); on.exit(dbDisconnect(con))
    df  <- dbGetQuery(con,"SELECT id FROM flowering f JOIN plants p ON f.plant_id=p.id ORDER BY f.start_date DESC")
    req(rows<=nrow(df)); fid <- df$id[rows]
    dbExecute(con,"UPDATE flowering SET start_date=?,end_date=?,flower_colour=?,pollination_notes=?,seeds_set=?,seed_notes=?,notes=? WHERE id=?",
      list(trimws(input$efl_start),trimws(input$efl_end),trimws(input$efl_colour),
           trimws(input$efl_pollination),as.integer(isTRUE(input$efl_seeds)),
           trimws(input$efl_seed_notes),trimws(input$efl_notes),fid))
    removeModal(); bump()
  })
  observeEvent(input$fl_del_btn,{
    rows <- input$flowering_history_rows_selected; req(length(rows)>0)
    con <- get_con(); on.exit(dbDisconnect(con))
    df  <- dbGetQuery(con,"SELECT id FROM flowering f JOIN plants p ON f.plant_id=p.id ORDER BY f.start_date DESC")
    req(rows<=nrow(df)); dbExecute(con,"DELETE FROM flowering WHERE id=?",list(df$id[rows])); bump()
  })


  # ════════════════════════════════════════════════════════════════════════════
  # RECORD > PHOTOS
  # ════════════════════════════════════════════════════════════════════════════
  ph_selected <- reactiveVal(NULL)

  observeEvent(input$ph_submit, {
    req(input$ph_plant != "")
    files <- input$ph_files
    if (is.null(files) || nrow(files) == 0) {
      output$ph_feedback_ui <- renderUI(
        tags$p("Please choose at least one photo file.", style="color:red;"))
      return()
    }
    con <- get_con(); on.exit(dbDisconnect(con))
    n_saved <- 0L
    for (i in seq_len(nrow(files))) {
      ext <- tolower(file_ext(files$name[i]))
      if (!ext %in% c("jpg","jpeg","png","webp")) next
      new_name <- sprintf("p%s_%s_%02d.%s",
        input$ph_plant, format(Sys.time(), "%Y%m%d%H%M%S"), i, ext)
      file.copy(files$datapath[i], file.path(PHOTO_DIR, new_name))
      dbExecute(con,
        "INSERT INTO photos (plant_id, photo_date, file_name, caption) VALUES (?,?,?,?)",
        list(as.integer(input$ph_plant), as.character(input$ph_date),
             new_name, trimws(input$ph_caption %||% "")))
      n_saved <- n_saved + 1L
    }
    output$ph_feedback_ui <- renderUI(
      tags$p(paste0("✓ ", n_saved, " photo(s) uploaded."),
             style="color:#2e7d32;font-weight:bold;"))
    ph_selected(NULL); bump()
  })

  output$ph_gallery <- renderUI({
    refresh()
    con <- get_con(); on.exit(dbDisconnect(con))
    filt <- input$ph_filter %||% ""
    q <- "SELECT p.id,p.file_name,p.photo_date,p.caption,pl.genus,pl.species
          FROM photos p JOIN plants pl ON p.plant_id=pl.id"
    if (nchar(filt) > 0) q <- paste0(q, sprintf(" WHERE p.plant_id=%s", filt))
    q <- paste0(q, " ORDER BY p.photo_date DESC")
    photos <- dbGetQuery(con, q)
    if (nrow(photos) == 0)
      return(tags$p("No photos yet.", style="color:#888;font-style:italic;"))
    tags$div(style="display:flex;flex-wrap:wrap;gap:10px;",
      lapply(seq_len(nrow(photos)), function(i) {
        r      <- photos[i,]
        fname  <- r$file_name
        cap    <- if (!is.na(r$caption) && r$caption != "") r$caption else ""
        pname  <- trimws(paste(r$genus, r$species %||% ""))
        is_sel <- isTRUE(ph_selected() == fname)
        brd    <- if (is_sel) "border:3px solid #2e7d32;" else "border:2px solid transparent;"
        tags$div(style=paste0("text-align:center;cursor:pointer;width:110px;",brd,"border-radius:6px;padding:3px;"),
          onclick=sprintf("Shiny.setInputValue('ph_click','%s',{priority:'event'})", fname),
          tags$a(href=paste0("photos/",fname), target="_blank",
            onclick="event.stopPropagation();",
            tags$img(src=paste0("photos/",fname),
              style="width:100px;height:100px;object-fit:cover;border-radius:4px;",
              title=paste0(pname, if(nchar(cap)>0) paste0(" — ",cap) else ""))),
          tags$div(style="font-size:10px;color:#555;margin-top:3px;word-break:break-word;", pname),
          tags$div(style="font-size:10px;color:#999;", r$photo_date)
        )
      })
    )
  })

  observeEvent(input$ph_click, {
    clicked <- input$ph_click
    if (isTRUE(ph_selected() == clicked)) ph_selected(NULL) else ph_selected(clicked)
  })

  output$ph_sel_ui <- renderUI({
    sel <- ph_selected(); if (is.null(sel)) return(NULL)
    tags$p(tags$em(paste0("Selected: ", sel)), style="font-size:12px;color:#555;margin-top:6px;")
  })

  observeEvent(input$ph_del_btn, {
    sel <- ph_selected(); req(!is.null(sel))
    showModal(modalDialog(title="Delete photo?",
      tags$p("Permanently delete ", tags$strong(sel), "?"),
      tags$p(tags$em("The image file and database record will both be removed.")),
      footer=tagList(modalButton("Cancel"),
        actionButton("ph_del_confirm","Delete",class="btn-danger"))))
  })

  observeEvent(input$ph_del_confirm, {
    sel <- ph_selected(); req(!is.null(sel))
    con <- get_con(); on.exit(dbDisconnect(con))
    dbExecute(con, "DELETE FROM photos WHERE file_name=?", list(sel))
    fpath <- file.path(PHOTO_DIR, sel)
    if (file.exists(fpath)) file.remove(fpath)
    removeModal(); ph_selected(NULL); bump()
  })

  # ════════════════════════════════════════════════════════════════════════════
  # RECORD > SOIL MIX
  # ════════════════════════════════════════════════════════════════════════════
  n_soil_rows <- reactiveVal(3)
  observeEvent(input$sm_add_row,{if(n_soil_rows()<10) n_soil_rows(n_soil_rows()+1)})

  output$soil_component_rows <- renderUI({
    n <- n_soil_rows(); refresh()
    con <- get_con(); on.exit(dbDisconnect(con))
    comp_choices <- distinct_vals(con,"soil_mix_components","component")
    tagList(lapply(seq_len(n),function(i) fluidRow(
      column(7,selectizeInput(paste0("sm_comp_",i),label=if(i==1)"Component" else NULL,
        choices=comp_choices,options=list(create=TRUE,placeholder="e.g. pumice"))),
      column(5,numericInput(paste0("sm_pct_",i),label=if(i==1)"%" else NULL,
        value=NA,min=0,max=100,step=5)))))
  })

  output$sm_total_pct <- renderText({
    total <- sum(vapply(seq_len(n_soil_rows()),function(i){
      v <- input[[paste0("sm_pct_",i)]]; if(is.null(v)||is.na(v)) 0 else v},numeric(1)))
    paste0("Total: ",total,"%")
  })

  observeEvent(input$sm_submit,{
    req(input$sm_plant!=""); n <- n_soil_rows()
    components <- Filter(Negate(is.null),lapply(seq_len(n),function(i){
      comp <- trimws(input[[paste0("sm_comp_",i)]] %||% "")
      pct  <- input[[paste0("sm_pct_",i)]]
      if(nchar(comp)>0) list(component=comp,percentage=if(is.null(pct)||is.na(pct)) NA_real_ else pct) else NULL
    }))
    if(length(components)==0){output$sm_feedback <- renderText("Please enter at least one component.");return()}
    con <- get_con(); on.exit(dbDisconnect(con))
    dbExecute(con,"INSERT INTO soil_mixes (plant_id,date_set,notes) VALUES (?,?,?)",
      list(as.integer(input$sm_plant),as.character(input$sm_date),trimws(input$sm_notes %||% "")))
    mix_id <- dbGetQuery(con,"SELECT last_insert_rowid() AS id")$id
    for(comp in components)
      dbExecute(con,"INSERT INTO soil_mix_components (mix_id,component,percentage) VALUES (?,?,?)",
        list(mix_id,comp$component,comp$percentage))
    output$sm_feedback <- renderText("\u2713 Soil mix saved."); n_soil_rows(3); bump()
  })

  output$soil_mix_history <- renderDT({
    refresh(); req(input$sm_plant!="")
    con <- get_con(); on.exit(dbDisconnect(con))
    mixes <- dbGetQuery(con,sprintf("SELECT id,date_set,notes FROM soil_mixes WHERE plant_id=%s ORDER BY date_set DESC",input$sm_plant))
    if(nrow(mixes)==0) return(datatable(data.frame(Message="No soil mixes recorded yet."),rownames=FALSE))
    result <- do.call(rbind,lapply(seq_len(nrow(mixes)),function(i){
      comps <- dbGetQuery(con,sprintf("SELECT component,percentage FROM soil_mix_components WHERE mix_id=%d ORDER BY percentage DESC",mixes$id[i]))
      comp_str <- if(nrow(comps)>0) paste(apply(comps,1,function(r){
        pct <- suppressWarnings(as.numeric(r["percentage"]))
        if(!is.na(pct)) paste0(r["component"]," (",pct,"%)") else r["component"]}),collapse=", ") else "\u2014"
      data.frame(date=mixes$date_set[i],components=comp_str,notes=mixes$notes[i] %||% "",stringsAsFactors=FALSE)
    }))
    datatable(result,selection="single",rownames=FALSE,options=list(pageLength=5,scrollX=TRUE))
  })

  selected_mix_id <- reactive({
    rows <- input$soil_mix_history_rows_selected
    req(length(rows)>0, input$sm_plant!="")
    con <- get_con(); on.exit(dbDisconnect(con))
    mixes <- dbGetQuery(con,sprintf("SELECT id FROM soil_mixes WHERE plant_id=%s ORDER BY date_set DESC",input$sm_plant))
    req(rows<=nrow(mixes))
    mixes$id[rows]
  })

  esm_n_rows <- reactiveVal(1L)

  observeEvent(input$sm_edit_btn, {
    mid <- selected_mix_id()
    con <- get_con(); on.exit(dbDisconnect(con))
    mix   <- dbGetQuery(con,sprintf("SELECT date_set,notes FROM soil_mixes WHERE id=%d",mid))
    comps <- dbGetQuery(con,sprintf("SELECT component,percentage FROM soil_mix_components WHERE mix_id=%d ORDER BY percentage DESC",mid))
    req(nrow(mix)>0)
    n <- max(nrow(comps),1L); esm_n_rows(n)
    comp_rows_ui <- lapply(seq_len(n),function(i){
      cval <- if(i<=nrow(comps)) na_str(comps$component[i]) else ""
      pval <- if(i<=nrow(comps)) comps$percentage[i] else NA_real_
      fluidRow(
        column(7,textInput(paste0("esm_comp_",i),label=if(i==1)"Component" else NULL,value=cval)),
        column(4,numericInput(paste0("esm_pct_",i),label=if(i==1)"%" else NULL,value=pval,min=0,max=100,step=5)),
        column(1,if(i>1) actionButton(paste0("esm_rem_",i),"",icon=icon("minus"),
          class="btn-xs btn-danger",style="margin-top:22px;") else NULL))
    })
    showModal(modalDialog(title="Edit soil mix",size="m",easyClose=TRUE,
      textInput("esm_date","Date (YYYY-MM-DD)",value=na_str(mix$date_set)),
      h5("Components"),
      tags$div(id="esm_comp_container",comp_rows_ui),
      actionButton("esm_add_row","+ Add row",class="btn-sm btn-default",
        style="margin-bottom:10px;"),
      tags$div(style="font-weight:bold;font-size:13px;margin-bottom:8px;",
        textOutput("esm_total_pct",inline=TRUE)),
      textAreaInput("esm_notes","Notes",value=na_str(mix$notes),rows=2),
      footer=tagList(modalButton("Cancel"),
        actionButton("esm_save","Save changes",class="btn-primary"))))
  })

  observeEvent(input$esm_add_row,{
    n <- esm_n_rows()+1L; esm_n_rows(n)
    con <- get_con(); on.exit(dbDisconnect(con))
    comp_choices <- distinct_vals(con,"soil_mix_components","component")
    insertUI(selector="#esm_comp_container",where="beforeEnd",
      ui=fluidRow(
        column(7,selectizeInput(paste0("esm_comp_",n),label=NULL,choices=comp_choices,
          options=list(create=TRUE,placeholder="e.g. pumice"))),
        column(4,numericInput(paste0("esm_pct_",n),label=NULL,value=NA,min=0,max=100,step=5)),
        column(1,actionButton(paste0("esm_rem_",n),"",icon=icon("minus"),
          class="btn-xs btn-danger"))))
  })

  output$esm_total_pct <- renderText({
    n <- esm_n_rows()
    total <- sum(vapply(seq_len(n),function(i){
      v <- input[[paste0("esm_pct_",i)]]; if(is.null(v)||is.na(v)) 0 else v},numeric(1)))
    paste0("Total: ",total,"%")
  })

  observeEvent(input$esm_save,{
    mid <- selected_mix_id(); n <- esm_n_rows()
    components <- Filter(Negate(is.null),lapply(seq_len(n),function(i){
      comp <- trimws(input[[paste0("esm_comp_",i)]] %||% "")
      pct  <- input[[paste0("esm_pct_",i)]]
      if(nchar(comp)>0) list(component=comp,
        percentage=if(is.null(pct)||is.na(pct)) NA_real_ else pct) else NULL
    }))
    if(length(components)==0) return()
    con <- get_con(); on.exit(dbDisconnect(con))
    dbExecute(con,"UPDATE soil_mixes SET date_set=?,notes=? WHERE id=?",
      list(trimws(input$esm_date),trimws(input$esm_notes %||% ""),mid))
    dbExecute(con,"DELETE FROM soil_mix_components WHERE mix_id=?",list(mid))
    for(comp in components)
      dbExecute(con,"INSERT INTO soil_mix_components (mix_id,component,percentage) VALUES (?,?,?)",
        list(mid,comp$component,comp$percentage))
    removeModal(); esm_n_rows(1L); bump()
  })

  observeEvent(input$sm_del_btn,{
    mid <- selected_mix_id()
    con <- get_con(); on.exit(dbDisconnect(con))
    mix <- dbGetQuery(con,sprintf("SELECT date_set FROM soil_mixes WHERE id=%d",mid))
    showModal(modalDialog(title="Delete soil mix?",
      tags$p("Permanently delete the soil mix recorded on ",tags$strong(mix$date_set),"?"),
      tags$p(tags$em("All component records for this mix will also be removed.")),
      footer=tagList(modalButton("Cancel"),
        actionButton("sm_del_confirm","Delete",class="btn-danger"))))
  })

  observeEvent(input$sm_del_confirm,{
    mid <- selected_mix_id()
    con <- get_con(); on.exit(dbDisconnect(con))
    dbExecute(con,"DELETE FROM soil_mix_components WHERE mix_id=?",list(mid))
    dbExecute(con,"DELETE FROM soil_mixes WHERE id=?",list(mid))
    removeModal(); bump()
  })


  # ════════════════════════════════════════════════════════════════════════════
  # EVENTS & NOTES (save + edit + delete)
  # ════════════════════════════════════════════════════════════════════════════
  observeEvent(input$e_submit,{
    req(input$e_plant!=""); con <- get_con(); on.exit(dbDisconnect(con))
    dbExecute(con,"INSERT INTO events (plant_id,event_date,event_type,notes) VALUES (?,?,?,?)",
      list(as.integer(input$e_plant),as.character(input$e_date),input$e_type,trimws(input$e_notes %||% "")))
    output$e_feedback <- renderText("\u2713 Event saved."); bump()
  })

  output$event_history <- renderDT({
    refresh(); con <- get_con(); on.exit(dbDisconnect(con))
    q <- "SELECT e.id,p.genus,p.species,e.event_date AS date,e.event_type AS type,e.notes FROM events e JOIN plants p ON e.plant_id=p.id"
    if(!is.null(input$e_filter_plant)&&input$e_filter_plant!="")
      q <- paste0(q," WHERE e.plant_id=",input$e_filter_plant)
    df <- dbGetQuery(con,paste0(q," ORDER BY e.event_date DESC"))
    datatable(df,selection="single",rownames=FALSE,options=list(pageLength=15,scrollX=TRUE))
  })

  observeEvent(input$e_edit_btn,{
    rows <- input$event_history_rows_selected; req(length(rows)>0)
    con <- get_con(); on.exit(dbDisconnect(con))
    q <- "SELECT e.id,e.event_date,e.event_type,e.notes FROM events e JOIN plants p ON e.plant_id=p.id"
    if(!is.null(input$e_filter_plant)&&input$e_filter_plant!="")
      q <- paste0(q," WHERE e.plant_id=",input$e_filter_plant)
    df <- dbGetQuery(con,paste0(q," ORDER BY e.event_date DESC"))
    req(rows<=nrow(df)); r <- df[rows,]
    showModal(modalDialog(title="Edit event",easyClose=TRUE,
      textInput("ee_date","Date (YYYY-MM-DD)",value=na_str(r$event_date)),
      selectInput("ee_type","Event type",
        choices=c("repot","water","fertilise","flower","treatment","propagate","dormancy start","dormancy end","other"),
        selected=r$event_type),
      textAreaInput("ee_notes","Notes",value=na_str(r$notes),rows=3),
      footer=tagList(modalButton("Cancel"),actionButton("ee_save","Save",class="btn-primary")),
      tags$input(type="hidden",id="ee_id",value=r$id)
    ))
  })
  observeEvent(input$ee_save,{
    rows <- input$event_history_rows_selected; req(length(rows)>0)
    con <- get_con(); on.exit(dbDisconnect(con))
    q <- "SELECT e.id FROM events e JOIN plants p ON e.plant_id=p.id"
    if(!is.null(input$e_filter_plant)&&input$e_filter_plant!="")
      q <- paste0(q," WHERE e.plant_id=",input$e_filter_plant)
    df <- dbGetQuery(con,paste0(q," ORDER BY e.event_date DESC"))
    req(rows<=nrow(df)); eid <- df$id[rows]
    dbExecute(con,"UPDATE events SET event_date=?,event_type=?,notes=? WHERE id=?",
      list(trimws(input$ee_date),input$ee_type,trimws(input$ee_notes),eid))
    removeModal(); bump()
  })
  observeEvent(input$e_del_btn,{
    rows <- input$event_history_rows_selected; req(length(rows)>0)
    con <- get_con(); on.exit(dbDisconnect(con))
    q <- "SELECT e.id FROM events e JOIN plants p ON e.plant_id=p.id"
    if(!is.null(input$e_filter_plant)&&input$e_filter_plant!="")
      q <- paste0(q," WHERE e.plant_id=",input$e_filter_plant)
    df <- dbGetQuery(con,paste0(q," ORDER BY e.event_date DESC"))
    req(rows<=nrow(df)); dbExecute(con,"DELETE FROM events WHERE id=?",list(df$id[rows])); bump()
  })


  # ════════════════════════════════════════════════════════════════════════════
  # GROWTH CHARTS
  # ════════════════════════════════════════════════════════════════════════════
  chart_data <- reactive({
    req(input$ch_plant!=""); refresh()
    con <- get_con(); on.exit(dbDisconnect(con))
    df  <- dbGetQuery(con,sprintf("SELECT meas_date,height_mm,width_mm,offsets FROM measurements WHERE plant_id=%s ORDER BY meas_date",input$ch_plant))
    df$meas_date <- as.Date(df$meas_date); df
  })

  output$growth_plot <- renderPlot({
    df <- chart_data(); metric <- input$ch_metric
    if(nrow(df)==0||all(is.na(df[[metric]]))){
      plot(1,type="n",axes=FALSE,xlab="",ylab=""); text(1,1,"No data yet for this plant / metric",cex=1.4,col="grey40"); return()}
    df_plot <- df[!is.na(df[[metric]]),]
    label   <- switch(metric,height_mm="Height (mm)",width_mm="Width (mm)",offsets="Offsets / heads / pads")
    p <- ggplot(df_plot,aes(x=meas_date,y=.data[[metric]]))+
      geom_line(colour="#2e7d32",linewidth=1.1)+geom_point(colour="#2e7d32",size=3.5)+
      labs(x="Date",y=label,title=label)+theme_minimal(base_size=14)+
      theme(plot.title=element_text(colour="#2e7d32",face="bold"))
    if(isTRUE(input$ch_events)){
      con <- get_con(); on.exit(dbDisconnect(con))
      ev  <- dbGetQuery(con,sprintf("SELECT event_date,event_type FROM events WHERE plant_id=%s",input$ch_plant))
      ev$event_date <- as.Date(ev$event_date)
      if(nrow(ev)>0){
        yr <- range(df_plot[[metric]],na.rm=TRUE); yp <- yr[1]+0.05*diff(yr)
        p  <- p+geom_vline(data=ev,aes(xintercept=event_date),linetype="dashed",colour="steelblue",alpha=0.6)+
          geom_text(data=ev,aes(x=event_date,y=yp,label=event_type),angle=90,vjust=-0.4,hjust=0,size=3.2,colour="steelblue")
      }
    }
    print(p)
  })

  output$ch_summary <- renderText({
    df <- chart_data(); metric <- input$ch_metric
    if(nrow(df)==0) return("No measurements recorded yet.")
    vals  <- df[[metric]][!is.na(df[[metric]])]
    if(length(vals)==0) return("No data for this metric.")
    dates <- df$meas_date[!is.na(df[[metric]])]
    days  <- as.numeric(difftime(tail(dates,1),dates[1],units="days"))
    paste0("Measurements:  ",length(vals),"\nFirst:         ",format(dates[1]),
           "\nLatest:        ",format(tail(dates,1)),"\nDays elapsed:  ",round(days),
           "\nFirst value:   ",vals[1],"\nLatest value:  ",tail(vals,1),
           "\nTotal change:  ",round(tail(vals,1)-vals[1],1),"\n",
           if(days>0) paste0("Rate:          ",round((tail(vals,1)-vals[1])/days*30,2)," units / month"))
  })

  output$latest_measurements <- renderDT({
    refresh(); con <- get_con(); on.exit(dbDisconnect(con))
    df <- dbGetQuery(con,"SELECT p.genus,p.species,p.cultivar,MAX(m.meas_date) AS last_measured,m.height_mm,m.width_mm,m.offsets FROM plants p LEFT JOIN measurements m ON p.id=m.plant_id WHERE p.status='active' GROUP BY p.id ORDER BY p.genus,p.species")
    datatable(df,rownames=FALSE,options=list(pageLength=20,scrollX=TRUE))
  })


  # ════════════════════════════════════════════════════════════════════════════
  # SEEDS — (all seed/germination server code preserved from Batch 2)
  # ════════════════════════════════════════════════════════════════════════════
  # Helper: convert an optional dateInput value to a character string or NA.
  # dateInput with value=NA returns an NA Date object; as.character() on that
  # produces the *string* "NA" rather than true NA_character_, which breaks
  # SQLite inserts. This guard catches both cases.
  safe_opt_date <- function(x) {
    if (is.null(x) || length(x) == 0) return(NA_character_)
    if (inherits(x, "Date") && is.na(x)) return(NA_character_)
    s <- suppressWarnings(as.character(x))
    if (is.na(s) || trimws(s) == "" || trimws(s) == "NA") return(NA_character_)
    s
  }

  # Default first germination date to match sow date when sow date changes
  observeEvent(input$sw_sow_date, {
    req(!is.null(input$sw_sow_date), !is.na(input$sw_sow_date))
    updateDateInput(session, "sw_first_germ", value = input$sw_sow_date)
  }, ignoreInit = TRUE)

  observeEvent(input$sw_submit,{
    req(nchar(trimws(input$sw_genus))>0)
    con <- get_con(); on.exit(dbDisconnect(con))
    enc_opened  <- safe_opt_date(input$sw_enc_opened)
    enc_removed <- safe_opt_date(input$sw_enc_removed)
    first_germ  <- safe_opt_date(input$sw_first_germ)
    dbExecute(con,"INSERT INTO sowings (genus,species,cultivar,sow_date,seed_origin,seed_age,n_seeds,date_first_germ,enclosure_type,enclosure_opened,enclosure_removed,heat_mat,heat_mat_notes,lights_notes,watering_notes,notes) VALUES (?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?)",
      list(trimws(input$sw_genus),trimws(input$sw_species %||% ""),trimws(input$sw_cultivar %||% ""),
           as.character(input$sw_sow_date),trimws(input$sw_origin %||% ""),trimws(input$sw_seed_age %||% ""),
           if(is.na(input$sw_n_seeds)) NA_integer_ else as.integer(input$sw_n_seeds),
           first_germ,trimws(input$sw_enclosure %||% ""),enc_opened,enc_removed,
           as.integer(isTRUE(input$sw_heat_mat)),trimws(input$sw_heat_notes %||% ""),
           trimws(input$sw_lights %||% ""),trimws(input$sw_watering %||% ""),trimws(input$sw_notes %||% "")))
    output$sw_feedback_ui <- renderUI(tags$p("\u2713 Sowing record saved.",style="color:#2e7d32;font-weight:bold;"))
    bump()
    for(id in c("sw_genus","sw_species","sw_cultivar","sw_seed_age","sw_enclosure","sw_heat_notes"))
      updateTextInput(session,id,value="")
    for(id in c("sw_lights","sw_watering","sw_notes")) updateTextAreaInput(session,id,value="")
    updateNumericInput(session,"sw_n_seeds",value=NA)
    updateSelectizeInput(session,"sw_origin",selected="")
    updateCheckboxInput(session,"sw_heat_mat",value=FALSE)
  })

  output$sowings_table_new <- renderDT({
    refresh(); con <- get_con(); on.exit(dbDisconnect(con))
    df <- dbGetQuery(con,"SELECT id,genus,species,sow_date,n_seeds,date_first_germ FROM sowings ORDER BY sow_date DESC")
    datatable(df,rownames=FALSE,options=list(pageLength=8,scrollX=TRUE))
  })

  output$sowings_table_main <- renderDT({
    refresh(); con <- get_con(); on.exit(dbDisconnect(con))
    df <- dbGetQuery(con,"SELECT s.id,s.genus,s.species,s.sow_date,s.n_seeds,s.date_first_germ,s.seed_origin,(SELECT COUNT(*) FROM seedling_counts sc WHERE sc.sowing_id=s.id) AS count_records,(SELECT COUNT(*) FROM plants p WHERE p.sowing_id=s.id) AS graduated FROM sowings s ORDER BY s.sow_date DESC")
    datatable(df,selection="single",rownames=FALSE,options=list(pageLength=10,scrollX=TRUE))
  })

  selected_sowing_id <- reactive({
    rows <- input$sowings_table_main_rows_selected; if(length(rows)==0) return(NULL)
    con <- get_con(); on.exit(dbDisconnect(con))
    df  <- dbGetQuery(con,"SELECT id FROM sowings ORDER BY sow_date DESC")
    if(rows>nrow(df)) return(NULL); df$id[rows]
  })

  # Edit sowing modal
  observeEvent(input$sw_edit_btn,{
    sid <- selected_sowing_id(); req(!is.null(sid))
    con <- get_con(); on.exit(dbDisconnect(con))
    s   <- dbGetQuery(con,sprintf("SELECT * FROM sowings WHERE id=%d",sid))
    req(nrow(s)>0)
    showModal(modalDialog(title=paste("Edit sowing:",s$genus,s$species %||% ""),size="l",easyClose=TRUE,
      fluidRow(
        column(6,
          textInput("esw_genus","Genus",value=na_str(s$genus)),
          textInput("esw_species","Species",value=na_str(s$species)),
          textInput("esw_sow_date","Sow date (YYYY-MM-DD)",value=na_str(s$sow_date)),
          numericInput("esw_n_seeds","Seeds sown",value=s$n_seeds,min=0),
          textInput("esw_origin","Seed origin",value=na_str(s$seed_origin)),
          textInput("esw_seed_age","Seed age",value=na_str(s$seed_age)),
          textInput("esw_first_germ","First germination (YYYY-MM-DD)",value=na_str(s$date_first_germ))
        ),
        column(6,
          textInput("esw_enclosure","Enclosure type",value=na_str(s$enclosure_type)),
          textInput("esw_enc_opened","Enclosure opened",value=na_str(s$enclosure_opened)),
          textInput("esw_enc_removed","Enclosure removed",value=na_str(s$enclosure_removed)),
          checkboxInput("esw_heat_mat","Heat mat",value=isTRUE(s$heat_mat==1L)),
          textInput("esw_heat_notes","Heat mat details",value=na_str(s$heat_mat_notes)),
          textAreaInput("esw_lights","Lights",value=na_str(s$lights_notes),rows=2),
          textAreaInput("esw_watering","Watering",value=na_str(s$watering_notes),rows=2),
          textAreaInput("esw_notes","Notes",value=na_str(s$notes),rows=2)
        )
      ),
      footer=tagList(modalButton("Cancel"),actionButton("esw_save","Save",class="btn-primary"))
    ))
  })
  observeEvent(input$esw_save,{
    sid <- selected_sowing_id(); req(!is.null(sid))
    con <- get_con(); on.exit(dbDisconnect(con))
    dbExecute(con,"UPDATE sowings SET genus=?,species=?,sow_date=?,n_seeds=?,seed_origin=?,seed_age=?,date_first_germ=?,enclosure_type=?,enclosure_opened=?,enclosure_removed=?,heat_mat=?,heat_mat_notes=?,lights_notes=?,watering_notes=?,notes=? WHERE id=?",
      list(trimws(input$esw_genus),trimws(input$esw_species),trimws(input$esw_sow_date),
           if(is.na(input$esw_n_seeds)) NA_integer_ else as.integer(input$esw_n_seeds),
           trimws(input$esw_origin),trimws(input$esw_seed_age),trimws(input$esw_first_germ),
           trimws(input$esw_enclosure),trimws(input$esw_enc_opened),trimws(input$esw_enc_removed),
           as.integer(isTRUE(input$esw_heat_mat)),trimws(input$esw_heat_notes),
           trimws(input$esw_lights),trimws(input$esw_watering),trimws(input$esw_notes),sid))
    removeModal(); bump()
  })
  observeEvent(input$sw_del_btn,{
    sid <- selected_sowing_id(); req(!is.null(sid))
    showModal(modalDialog(title="Delete sowing?",
      tags$p("This will delete the sowing record only. Seedling counts, sowing events, and any graduated plants are kept."),
      footer=tagList(modalButton("Cancel"),actionButton("sw_del_confirm","Delete",class="btn-danger"))))
  })
  observeEvent(input$sw_del_confirm,{
    sid <- selected_sowing_id(); req(!is.null(sid))
    con <- get_con(); on.exit(dbDisconnect(con))
    dbExecute(con,"DELETE FROM sowings WHERE id=?",list(sid))
    removeModal(); bump()
  })

  output$sowing_detail_panel <- renderUI({
    sid <- selected_sowing_id(); if(is.null(sid)) return(NULL)
    con <- get_con(); on.exit(dbDisconnect(con))
    s   <- dbGetQuery(con,sprintf("SELECT * FROM sowings WHERE id=%d",sid))
    if(nrow(s)==0) return(NULL)
    last_ct <- dbGetQuery(con,sprintf("SELECT count_date,n_surviving FROM seedling_counts WHERE sowing_id=%d ORDER BY count_date DESC LIMIT 1",sid))
    pct_str <- "\u2014"
    if(nrow(last_ct)>0&&!is.na(s$n_seeds)&&s$n_seeds>0)
      pct_str <- paste0(last_ct$n_surviving," / ",s$n_seeds," (",round(last_ct$n_surviving/s$n_seeds*100,1),"%) as at ",last_ct$count_date)
    else if(nrow(last_ct)>0)
      pct_str <- paste0(last_ct$n_surviving," surviving as at ",last_ct$count_date)
    fluidRow(box(width=12,title=paste(s$genus,s$species %||% "","— sown",s$sow_date),status="warning",collapsible=TRUE,
      fluidRow(
        column(4,
          tags$p(tags$span("Seed origin:",class="detail-label"),s$seed_origin %||% "\u2014"),
          tags$p(tags$span("Seed age:",class="detail-label"),s$seed_age %||% "\u2014"),
          tags$p(tags$span("Seeds sown:",class="detail-label"),s$n_seeds %||% "\u2014"),
          tags$p(tags$span("First germinated:",class="detail-label"),s$date_first_germ %||% "\u2014"),
          tags$p(tags$span("Surviving (latest):",class="detail-label"),pct_str)
        ),
        column(4,
          tags$p(tags$span("Enclosure:",class="detail-label"),s$enclosure_type %||% "\u2014"),
          tags$p(tags$span("Enclosure opened:",class="detail-label"),s$enclosure_opened %||% "\u2014"),
          tags$p(tags$span("Enclosure removed:",class="detail-label"),s$enclosure_removed %||% "\u2014"),
          tags$p(tags$span("Heat mat:",class="detail-label"),
            if(isTRUE(s$heat_mat==1L)) paste("Yes —",s$heat_mat_notes %||% "") else "No"),
          tags$p(tags$span("Lights:",class="detail-label"),s$lights_notes %||% "\u2014")
        ),
        column(4,
          tags$p(tags$span("Watering:",class="detail-label"),s$watering_notes %||% "\u2014"),
          tags$p(tags$span("Notes:",class="detail-label")),
          tags$p(style="white-space:pre-wrap;",s$notes %||% "\u2014")
        )
      )
    ))
  })

  observeEvent(input$sl_submit,{
    req(input$sl_sowing!="",!is.na(input$sl_n))
    con <- get_con(); on.exit(dbDisconnect(con))
    dbExecute(con,"INSERT INTO seedling_counts (sowing_id,count_date,n_surviving,notes) VALUES (?,?,?,?)",
      list(as.integer(input$sl_sowing),as.character(input$sl_date),as.integer(input$sl_n),trimws(input$sl_notes %||% "")))
    output$sl_feedback <- renderText("\u2713 Count saved."); bump()
  })
  observeEvent(input$se_submit,{
    req(input$sl_sowing!=""); con <- get_con(); on.exit(dbDisconnect(con))
    dbExecute(con,"INSERT INTO sowing_events (sowing_id,event_date,event_type,notes) VALUES (?,?,?,?)",
      list(as.integer(input$sl_sowing),as.character(input$se_date),input$se_type,trimws(input$se_notes %||% "")))
    output$se_feedback <- renderText("\u2713 Event saved."); bump()
  })

  output$sl_history <- renderDT({
    refresh(); req(input$sl_sowing!="")
    con <- get_con(); on.exit(dbDisconnect(con))
    df  <- dbGetQuery(con,sprintf("SELECT sc.id,sc.count_date AS date,sc.n_surviving,ROUND(CAST(sc.n_surviving AS REAL)/NULLIF(s.n_seeds,0)*100,1) AS pct_surviving,sc.notes FROM seedling_counts sc JOIN sowings s ON sc.sowing_id=s.id WHERE sc.sowing_id=%s ORDER BY sc.count_date",input$sl_sowing))
    datatable(df,selection="single",rownames=FALSE,options=list(pageLength=10,scrollX=TRUE))
  })

  observeEvent(input$sl_edit_btn,{
    rows <- input$sl_history_rows_selected; req(length(rows)>0)
    con <- get_con(); on.exit(dbDisconnect(con))
    df  <- dbGetQuery(con,sprintf("SELECT id,count_date,n_surviving,notes FROM seedling_counts WHERE sowing_id=%s ORDER BY count_date",input$sl_sowing))
    req(rows<=nrow(df)); r <- df[rows,]
    showModal(modalDialog(title="Edit seedling count",easyClose=TRUE,
      textInput("esc_date","Date (YYYY-MM-DD)",value=na_str(r$count_date)),
      numericInput("esc_n","Surviving seedlings",value=r$n_surviving,min=0),
      textAreaInput("esc_notes","Notes",value=na_str(r$notes),rows=2),
      footer=tagList(modalButton("Cancel"),actionButton("esc_save","Save",class="btn-primary")),
      tags$input(type="hidden",id="esc_id",value=r$id)
    ))
  })
  observeEvent(input$esc_save,{
    rows <- input$sl_history_rows_selected; req(length(rows)>0)
    con <- get_con(); on.exit(dbDisconnect(con))
    df  <- dbGetQuery(con,sprintf("SELECT id FROM seedling_counts WHERE sowing_id=%s ORDER BY count_date",input$sl_sowing))
    req(rows<=nrow(df)); scid <- df$id[rows]
    dbExecute(con,"UPDATE seedling_counts SET count_date=?,n_surviving=?,notes=? WHERE id=?",
      list(trimws(input$esc_date),as.integer(input$esc_n),trimws(input$esc_notes),scid))
    removeModal(); bump()
  })
  observeEvent(input$sl_del_btn,{
    rows <- input$sl_history_rows_selected; req(length(rows)>0)
    con <- get_con(); on.exit(dbDisconnect(con))
    df  <- dbGetQuery(con,sprintf("SELECT id FROM seedling_counts WHERE sowing_id=%s ORDER BY count_date",input$sl_sowing))
    req(rows<=nrow(df)); dbExecute(con,"DELETE FROM seedling_counts WHERE id=?",list(df$id[rows])); bump()
  })

  output$se_history <- renderDT({
    refresh(); req(input$sl_sowing!="")
    con <- get_con(); on.exit(dbDisconnect(con))
    df  <- dbGetQuery(con,sprintf("SELECT event_date AS date,event_type AS type,notes FROM sowing_events WHERE sowing_id=%s ORDER BY event_date DESC",input$sl_sowing))
    datatable(df,rownames=FALSE,options=list(pageLength=8,scrollX=TRUE))
  })

  survival_data <- reactive({
    req(input$sc_sowing!=""); refresh()
    con <- get_con(); on.exit(dbDisconnect(con))
    df  <- dbGetQuery(con,sprintf("SELECT sc.count_date,sc.n_surviving,s.n_seeds FROM seedling_counts sc JOIN sowings s ON sc.sowing_id=s.id WHERE sc.sowing_id=%s ORDER BY sc.count_date",input$sc_sowing))
    df$count_date <- as.Date(df$count_date); df
  })

  output$survival_plot <- renderPlot({
    df <- survival_data()
    if(nrow(df)==0){plot(1,type="n",axes=FALSE,xlab="",ylab="");text(1,1,"No count records for this sowing",cex=1.4,col="grey40");return()}
    use_pct <- isTRUE(input$sc_pct)&&!is.na(df$n_seeds[1])&&df$n_seeds[1]>0
    df$y    <- if(use_pct) df$n_surviving/df$n_seeds[1]*100 else df$n_surviving
    ylabel  <- if(use_pct) "Surviving (%)" else "Surviving seedlings (n)"
    p <- ggplot(df,aes(x=count_date,y=y))+
      geom_area(fill="#ce93d8",alpha=0.25)+geom_line(colour="#6a1b9a",linewidth=1.1)+
      geom_point(colour="#6a1b9a",size=3.5)+labs(x="Date",y=ylabel,title="Seedling survival")+
      theme_minimal(base_size=14)+theme(plot.title=element_text(colour="#6a1b9a",face="bold"))
    if(use_pct) p <- p+scale_y_continuous(limits=c(0,100))
    if(isTRUE(input$sc_events)){
      con <- get_con(); on.exit(dbDisconnect(con))
      ev  <- dbGetQuery(con,sprintf("SELECT event_date,event_type FROM sowing_events WHERE sowing_id=%s",input$sc_sowing))
      ev$event_date <- as.Date(ev$event_date)
      if(nrow(ev)>0){
        yr <- range(df$y,na.rm=TRUE); yp <- yr[1]+0.05*diff(yr)
        p  <- p+geom_vline(data=ev,aes(xintercept=event_date),linetype="dashed",colour="#e65100",alpha=0.7)+
          geom_text(data=ev,aes(x=event_date,y=yp,label=event_type),angle=90,vjust=-0.4,hjust=0,size=3,colour="#e65100")
      }
    }
    print(p)
  })

  output$sc_summary <- renderText({
    df <- survival_data(); if(nrow(df)==0) return("No count records yet.")
    n_seeds <- df$n_seeds[1]; last_n <- tail(df$n_surviving,1)
    days    <- as.numeric(difftime(tail(df$count_date,1),df$count_date[1],units="days"))
    pct_str <- if(!is.na(n_seeds)&&n_seeds>0) paste0("\nSurvival rate:  ",round(last_n/n_seeds*100,1),"%") else ""
    paste0("Count records:  ",nrow(df),"\nSeeds sown:     ",n_seeds %||% "?",
           "\nFirst count:    ",df$n_surviving[1]," (",format(df$count_date[1]),")",
           "\nLatest count:   ",last_n," (",format(tail(df$count_date,1)),")",
           "\nDays tracked:   ",round(days),pct_str)
  })

  output$gr_sowing_info <- renderUI({
    req(input$gr_sowing!=""); con <- get_con(); on.exit(dbDisconnect(con))
    sw <- dbGetQuery(con,sprintf("SELECT genus,species,sow_date,seed_origin,date_first_germ,n_seeds FROM sowings WHERE id=%s",input$gr_sowing))
    if(nrow(sw)==0) return(NULL)
    tags$div(style="background:#f3e5f5;border-radius:6px;padding:10px;margin:8px 0;font-size:13px;",
      tags$strong(paste(sw$genus,sw$species %||% "")),tags$br(),
      paste0("Sown: ",sw$sow_date,
        if(!is.na(sw$seed_origin)&&sw$seed_origin!="") paste0("  |  Origin: ",sw$seed_origin) else "",
        if(!is.na(sw$date_first_germ)&&sw$date_first_germ!="") paste0("  |  First germ: ",sw$date_first_germ) else ""))
  })

  observeEvent(input$gr_submit,{
    req(input$gr_sowing!=""); con <- get_con(); on.exit(dbDisconnect(con))
    sw <- dbGetQuery(con,sprintf("SELECT * FROM sowings WHERE id=%s",input$gr_sowing))
    req(nrow(sw)>0)
    dbExecute(con,"INSERT INTO plants (genus,species,cultivar,common_name,source,acquired,notes,sowing_id,status) VALUES (?,?,?,?,?,?,?,?,?)",
      list(sw$genus,sw$species %||% "",trimws(input$gr_cultivar %||% ""),trimws(input$gr_common %||% ""),
           "seed",as.character(input$gr_date),trimws(input$gr_notes %||% ""),as.integer(input$gr_sowing),"active"))
    new_id <- dbGetQuery(con,"SELECT last_insert_rowid() AS id")$id
    output$gr_feedback_ui <- renderUI(tags$p(paste0("\u2713 Plant record created (ID ",new_id,")."),style="color:#2e7d32;font-weight:bold;"))
    bump()
    for(id in c("gr_cultivar","gr_common")) updateTextInput(session,id,value="")
    updateTextAreaInput(session,"gr_notes",value="")
  })

  output$graduated_plants <- renderDT({
    refresh(); con <- get_con(); on.exit(dbDisconnect(con))
    df <- dbGetQuery(con,"SELECT s.genus,s.species,s.sow_date,p.id AS plant_id,p.cultivar,p.acquired AS potted_up,p.status FROM plants p JOIN sowings s ON p.sowing_id=s.id ORDER BY s.sow_date DESC,p.acquired")
    datatable(df,rownames=FALSE,options=list(pageLength=10,scrollX=TRUE))
  })


  # ════════════════════════════════════════════════════════════════════════════
  # TOOLS — LABELS
  # ════════════════════════════════════════════════════════════════════════════
  label_data <- reactive({
    refresh()
    con <- get_con(); on.exit(dbDisconnect(con))
    if(!is.null(input$lbl_scope)&&input$lbl_scope=="selected"&&!is.null(input$lbl_plant)&&input$lbl_plant!="")
      dbGetQuery(con,sprintf("SELECT * FROM plants WHERE id=%s",input$lbl_plant))
    else
      dbGetQuery(con,"SELECT * FROM plants WHERE status='active' ORDER BY genus,species")
  })

  output$lbl_preview <- renderUI({
    df     <- label_data(); if(nrow(df)==0) return(tags$p("No plants to preview."))
    fields <- input$lbl_fields %||% c("genus_species","origin_geo","acquired")
    w      <- input$lbl_w %||% 55; h <- input$lbl_h %||% 19
    font   <- input$lbl_font %||% 7; brd <- isTRUE(input$lbl_border)
    r      <- df[1,]
    name   <- paste(na_str(r$genus),na_str(r$species))
    if(!is.na(r$cultivar)&&r$cultivar!="") name <- paste0(name," '",r$cultivar,"'")
    field_labels <- c(genus_species="Name",family="Family",common_name="Common",
      origin_geo="Origin",origin_soil="Substrate",acquired="Planted",source="Source",
      supplier="Supplier",dormancy="Dormancy",toxicity="Toxicity",notes="Notes",llifle_url="Llifle")
    lines <- list()
    if("genus_species" %in% fields)
      lines[[length(lines)+1]] <- tags$div(style=paste0("font-weight:bold;font-size:",font,"pt;line-height:1.3;"),name)
    for(f in setdiff(fields,"genus_species")){
      val <- na_str(r[[f]]); if(nchar(val)==0) next
      lines[[length(lines)+1]] <- tags$div(
        style=paste0("font-size:",max(font-1L,5L),"pt;line-height:1.3;"),
        tags$span(style="font-weight:600;",paste0(field_labels[[f]],": ")),val)
    }
    brd_style <- if(brd) "border:1px solid #888;" else ""
    tags$div(class="label-preview",
      tags$p(tags$em(paste0("Preview: ",w,"mm \u00d7 ",h,"mm label"),
        style="color:#888;font-size:11px;margin:0 0 8px 0;")),
      tags$div(style=paste0("width:",w,"mm;min-height:",h,"mm;padding:1mm;box-sizing:border-box;",
        brd_style,"background:#fff;display:inline-block;"),
        lines))
  })

  output$lbl_download <- downloadHandler(
    filename=function() paste0("cactus_labels_",format(Sys.Date(),"%Y%m%d"),".html"),
    content=function(file){
      df     <- label_data()
      fields <- input$lbl_fields %||% c("genus_species","origin_geo","acquired")
      w      <- input$lbl_w %||% 55; h <- input$lbl_h %||% 19
      font   <- as.integer(input$lbl_font %||% 7)
      brd    <- isTRUE(input$lbl_border)
      writeLines(make_label_html(df,fields,w,h,font,brd),file)
    }
  )


  # ════════════════════════════════════════════════════════════════════════════
  # TOOLS — EXPORT
  # ════════════════════════════════════════════════════════════════════════════
  output$exp_download <- downloadHandler(
    filename=function() paste0("cactus_collection_",format(Sys.Date(),"%Y%m%d"),".xlsx"),
    content=function(file){
      con  <- get_con(); on.exit(dbDisconnect(con))
      wb   <- createWorkbook()
      tbls <- input$exp_tables %||% "plants"
      stat <- input$exp_status %||% "active"
      plant_filter <- if(stat=="active") "WHERE status='active'" else ""

      queries <- list(
        plants          = paste("SELECT * FROM plants",plant_filter,"ORDER BY genus,species"),
        measurements    = "SELECT p.genus,p.species,p.cultivar,m.meas_date,m.height_mm,m.width_mm,m.offsets,m.notes FROM measurements m JOIN plants p ON m.plant_id=p.id ORDER BY p.genus,p.species,m.meas_date",
        events          = "SELECT p.genus,p.species,e.event_date,e.event_type,e.notes FROM events e JOIN plants p ON e.plant_id=p.id ORDER BY p.genus,p.species,e.event_date",
        flowering       = "SELECT p.genus,p.species,f.start_date,f.end_date,f.flower_colour,f.seeds_set,f.pollination_notes,f.seed_notes,f.notes FROM flowering f JOIN plants p ON f.plant_id=p.id ORDER BY p.genus,p.species,f.start_date",
        soil_mixes      = "SELECT p.genus,p.species,sm.date_set,sm.notes,GROUP_CONCAT(smc.component||' '||COALESCE(smc.percentage||'%',''),', ') AS components FROM soil_mixes sm JOIN plants p ON sm.plant_id=p.id LEFT JOIN soil_mix_components smc ON smc.mix_id=sm.id GROUP BY sm.id ORDER BY p.genus,p.species,sm.date_set",
        sowings         = "SELECT * FROM sowings ORDER BY sow_date DESC",
        seedling_counts = "SELECT s.genus,s.species,s.sow_date,sc.count_date,sc.n_surviving,s.n_seeds,ROUND(CAST(sc.n_surviving AS REAL)/NULLIF(s.n_seeds,0)*100,1) AS pct,sc.notes FROM seedling_counts sc JOIN sowings s ON sc.sowing_id=s.id ORDER BY s.genus,s.species,sc.count_date",
        sowing_events   = "SELECT s.genus,s.species,s.sow_date,se.event_date,se.event_type,se.notes FROM sowing_events se JOIN sowings s ON se.sowing_id=s.id ORDER BY s.genus,s.species,se.event_date"
      )

      sheet_names <- c(plants="Plants",measurements="Measurements",events="Events",
        flowering="Flowering",soil_mixes="Soil Mixes",sowings="Sowings",
        seedling_counts="Seedling Counts",sowing_events="Sowing Events")

      for(tbl in intersect(tbls,names(queries))){
        df <- dbGetQuery(con,queries[[tbl]])
        addWorksheet(wb,sheet_names[[tbl]])
        writeDataTable(wb,sheet_names[[tbl]],df,tableStyle="TableStyleMedium9")
        setColWidths(wb,sheet_names[[tbl]],cols=seq_len(ncol(df)),widths="auto")
      }
      saveWorkbook(wb,file,overwrite=TRUE)
    }
  )


  # ════════════════════════════════════════════════════════════════════════════
  # TOOLS — IMPORT
  # ════════════════════════════════════════════════════════════════════════════
  imp_data <- reactive({
    f <- input$imp_file; req(!is.null(f))
    ext <- tolower(file_ext(f$name))
    tryCatch({
      if(ext=="csv") read.csv(f$datapath,stringsAsFactors=FALSE,check.names=FALSE)
      else           as.data.frame(read_excel(f$datapath))
    },error=function(e){ showNotification(paste("Error reading file:",e$message),type="error"); NULL})
  })

  output$imp_preview <- renderDT({
    df <- imp_data(); req(!is.null(df))
    # Show parsed date alongside raw value so user can verify before importing
    acq_col <- input$imp_map_acquired %||% ""
    preview  <- head(df, 6)
    if (nchar(acq_col) > 0 && acq_col %in% names(preview)) {
      preview[[paste0(acq_col, " → parsed")]] <-
        vapply(as.character(preview[[acq_col]]), smart_date, character(1))
    }
    datatable(preview, rownames=FALSE, options=list(scrollX=TRUE, dom="t"))
  })

  output$imp_mapping_ui <- renderUI({
    df <- imp_data(); req(!is.null(df))
    src_cols <- c("—"="", setNames(names(df),names(df)))
    db_fields <- c("genus *"="genus","species"="species","cultivar"="cultivar",
      "common_name"="common_name","family"="family","source"="source",
      "supplier"="supplier","acquired"="acquired","origin_geo"="origin_geo",
      "origin_soil"="origin_soil","dormancy"="dormancy","notes"="notes")
    tagList(
      hr(),h4("Map columns to database fields"),
      tags$p(tags$em("'genus' is required. All others optional.",
        style="color:#666;font-size:13px;")),
      lapply(seq_along(db_fields),function(i){
        fname <- names(db_fields)[i]; fval <- db_fields[i]
        # Try to auto-select a matching column name
        auto <- if(fval %in% names(df)) fval else ""
        fluidRow(
          column(5,tags$p(fname,style="padding-top:6px;font-weight:600;")),
          column(7,selectInput(paste0("imp_map_",fval),"",choices=src_cols,selected=auto))
        )
      })
    )
  })

  output$imp_ready <- reactive({ !is.null(imp_data()) })
  outputOptions(output,"imp_ready",suspendWhenHidden=FALSE)

  observeEvent(input$imp_submit,{
    df <- imp_data(); req(!is.null(df))
    db_fields <- c("genus","species","cultivar","common_name","family","source",
      "supplier","acquired","origin_geo","origin_soil","dormancy","notes")
    mapping <- setNames(
      vapply(db_fields,function(f) input[[paste0("imp_map_",f)]] %||% "",character(1)),
      db_fields)
    genus_col <- mapping["genus"]
    if(genus_col==""){
      output$imp_feedback_ui <- renderUI(tags$p("Please map the 'genus' column.",style="color:red;"))
      return()
    }
    con   <- get_con(); on.exit(dbDisconnect(con))
    n_ok  <- 0L; n_skip <- 0L
    for(i in seq_len(nrow(df))){
      genus_val <- trimws(as.character(df[[genus_col]][i]))
      if(is.na(genus_val)||genus_val==""){n_skip <- n_skip+1L; next}
      get_val <- function(f){
        col <- mapping[f]
        if (col==""||is.null(col)) return(NA_character_)
        v <- df[[col]][i]
        if (is.na(v)) return(NA_character_)
        val <- trimws(as.character(v))
        if (f == "acquired") val <- smart_date(val)
        val
      }
      tryCatch({
        dbExecute(con,"INSERT INTO plants (genus,species,cultivar,common_name,family,source,supplier,acquired,origin_geo,origin_soil,dormancy,notes,status) VALUES (?,?,?,?,?,?,?,?,?,?,?,?,'active')",
          list(genus_val,get_val("species"),get_val("cultivar"),get_val("common_name"),
               get_val("family"),get_val("source"),get_val("supplier"),get_val("acquired"),
               get_val("origin_geo"),get_val("origin_soil"),get_val("dormancy"),get_val("notes")))
        n_ok <- n_ok+1L
      },error=function(e) {n_skip <<- n_skip+1L})
    }
    output$imp_feedback_ui <- renderUI(
      tags$p(paste0("\u2713 Imported ",n_ok," plant(s). Skipped ",n_skip," row(s)."),
             style="color:#2e7d32;font-weight:bold;"))
    bump()
  })

  # ════════════════════════════════════════════════════════════════════════════
  # GALLERY
  # ════════════════════════════════════════════════════════════════════════════

  # Populate family/genus filter dropdowns
  observe({
    refresh()
    con <- get_con(); on.exit(dbDisconnect(con))
    families <- c("All families"="", distinct_vals(con,"plants","family"))
    updateSelectInput(session,"gal_family", choices=families)
  })

  observeEvent(input$gal_family, {
    con <- get_con(); on.exit(dbDisconnect(con))
    q <- "SELECT DISTINCT genus FROM plants WHERE genus IS NOT NULL AND genus != ''"
    if (!is.null(input$gal_family) && nchar(input$gal_family)>0)
      q <- paste0(q, sprintf(" AND family='%s'", gsub("'","''",input$gal_family)))
    q <- paste0(q," ORDER BY genus")
    genera <- dbGetQuery(con,q)$genus
    updateSelectInput(session,"gal_genus",
      choices=c("All genera"="", setNames(genera,genera)))
  }, ignoreInit=FALSE)

  output$gallery_ui <- renderUI({
    refresh()
    con <- get_con(); on.exit(dbDisconnect(con))

    fam  <- input$gal_family %||% ""
    gen  <- input$gal_genus  %||% ""
    srch <- trimws(input$gal_search %||% "")

    q_plants <- "SELECT p.id, p.family, p.genus, p.species, p.cultivar
                 FROM plants p WHERE p.status='active'"
    if (nchar(fam)>0)  q_plants <- paste0(q_plants, sprintf(" AND p.family='%s'",  gsub("'","''",fam)))
    if (nchar(gen)>0)  q_plants <- paste0(q_plants, sprintf(" AND p.genus='%s'",   gsub("'","''",gen)))
    if (nchar(srch)>0) q_plants <- paste0(q_plants, sprintf(
      " AND (p.species LIKE '%%%1$s%%' OR p.cultivar LIKE '%%%1$s%%')", gsub("'","''",srch)))
    q_plants <- paste0(q_plants," ORDER BY p.family, p.genus, p.species")
    plants   <- dbGetQuery(con, q_plants)

    if (nrow(plants)==0)
      return(tags$p("No plants match the current filter.",
        style="color:#888;font-style:italic;padding:20px;"))

    pid_list   <- paste(plants$id, collapse=",")
    all_photos <- dbGetQuery(con, sprintf(
      "SELECT plant_id, file_name, photo_date, caption
       FROM photos WHERE plant_id IN (%s) ORDER BY photo_date", pid_list))

    show_unphoto <- isTRUE(input$gal_unphoto)

    # ── Build a flat ordered list of ALL photos for the lightbox ─────────────
    # This lets the user arrow through the entire (filtered) gallery.
    all_ordered <- all_photos  # already ordered by plant then date

    # Helper: escape text for embedding in HTML attributes / JS strings
    esc_html <- function(x) {
      x <- gsub("&",  "&amp;",  x)
      x <- gsub("<",  "&lt;",   x)
      x <- gsub(">",  "&gt;",   x)
      x <- gsub('"',  "&quot;", x)
      x
    }
    esc_js <- function(x) gsub("'", "\\'", x, fixed=TRUE)

    # Build the JS array of all photos as a single assignment we inject once
    js_all <- paste0("var LB_PHOTOS=[",
      paste(sapply(seq_len(nrow(all_ordered)), function(i) {
        ph    <- all_ordered[i,]
        cap   <- if(!is.na(ph$caption)&&ph$caption!="") ph$caption else ""
        pname <- ""  # filled below after we join to plants
        sprintf("'photos/%s'", ph$file_name)   # just the src; caption shown separately
      }), collapse=","),
    "];")

    # Better: build full objects
    plant_name_map <- setNames(
      paste0(trimws(paste(plants$genus, ifelse(is.na(plants$species),"",plants$species)))),
      as.character(plants$id))

    js_objects <- paste(sapply(seq_len(nrow(all_ordered)), function(i) {
      ph   <- all_ordered[i,]
      cap  <- if(!is.na(ph$caption)&&ph$caption!="") esc_js(ph$caption) else ""
      pnm  <- esc_js(plant_name_map[as.character(ph$plant_id)] %||% "")
      sprintf("{src:'photos/%s',name:'%s',cap:'%s',date:'%s'}",
        ph$file_name, pnm, cap, ph$photo_date)
    }), collapse=",")

    # Map file_name -> index in all_ordered (0-based for JS)
    photo_idx <- setNames(seq_len(nrow(all_ordered))-1L, all_ordered$file_name)

    # ── Generate HTML ─────────────────────────────────────────────────────────
    families_present <- sort(unique(ifelse(is.na(plants$family)|plants$family=="",
      "(No family set)", plants$family)))

    sections_html <- paste(sapply(families_present, function(fam_name) {
      fam_key   <- if(fam_name=="(No family set)") "" else fam_name
      fam_plants <- plants[
        (!is.na(plants$family) & plants$family==fam_key) |
        ((is.na(plants$family)|plants$family=="") & fam_name=="(No family set)"), ]

      genera_blocks <- paste(sapply(sort(unique(fam_plants$genus)), function(g) {
        g_plants <- fam_plants[fam_plants$genus==g, ]

        sp_blocks <- paste(sapply(seq_len(nrow(g_plants)), function(j) {
          plant  <- g_plants[j,]
          pid    <- plant$id
          p_photos <- all_photos[all_photos$plant_id==pid, ]

          sp_name <- trimws(paste(
            if(!is.na(plant$species)&&plant$species!="") plant$species else "",
            if(!is.na(plant$cultivar)&&plant$cultivar!="")
              paste0("'",plant$cultivar,"'") else ""))
          if(nchar(trimws(sp_name))==0) sp_name <- paste("plant ID", pid)

          if(nrow(p_photos)==0 && !show_unphoto)
            return("")

          goto_js <- sprintf(
            "Shiny.setInputValue('gal_goto_plant',%d,{priority:'event'})", pid)

          if(nrow(p_photos)==0) {
            return(sprintf(
              '<div class="gallery-species"><em>%s</em>
               <span style="color:#bbb;font-size:11px;">(no photos)</span>
               <a href="#" onclick="%s;return false;"
                  style="font-size:11px;margin-left:8px;color:#2e7d32;">
                  \u2192 plant record</a></div>',
              esc_html(sp_name), esc_html(goto_js)))
          }

          thumb_html <- paste(sapply(seq_len(nrow(p_photos)), function(k) {
            ph    <- p_photos[k,]
            cap   <- if(!is.na(ph$caption)&&ph$caption!="") ph$caption else ""
            ttl   <- esc_html(if(nchar(cap)>0) cap else
                       paste(g, sp_name, ph$photo_date))
            lb_idx <- photo_idx[ph$file_name]
            sprintf(
              '<div class="gallery-card">
                <img src="photos/%s" class="gallery-thumb" title="%s"
                     onclick="lbOpen(%d)">
                %s
                <div class="gallery-date">%s</div>
               </div>',
              ph$file_name, ttl, lb_idx,
              if(nchar(cap)>0)
                sprintf('<div class="gallery-caption">%s</div>', esc_html(cap))
              else "",
              ph$photo_date)
          }), collapse="\n")

          sprintf(
            '<div class="gallery-section">
              <div class="gallery-species">
                <em>%s</em>
                <span style="color:#aaa;font-size:11px;margin-left:6px;">
                  (%d photo%s)</span>
                <a href="#" onclick="%s;return false;"
                   style="font-size:11px;margin-left:8px;color:#2e7d32;">
                   \u2192 plant record</a>
              </div>
              <div style="display:flex;flex-wrap:wrap;">%s</div>
            </div>',
            esc_html(sp_name),
            nrow(p_photos), if(nrow(p_photos)!=1)"s" else "",
            esc_html(goto_js),
            thumb_html)
        }), collapse="\n")

        if(nchar(trimws(gsub("<[^>]*>","",sp_blocks)))==0) return("")
        sprintf('<div>
          <div class="gallery-genus"><span style="font-style:italic;">%s</span></div>
          %s</div>',
          esc_html(g), sp_blocks)
      }), collapse="\n")

      if(nchar(trimws(gsub("<[^>]*>","",genera_blocks)))==0) return("")
      sprintf('<div style="margin-bottom:24px;">
        <h4 style="background:#e8f5e9;padding:8px 12px;border-radius:6px;
                   border-left:4px solid #2e7d32;margin-bottom:10px;">%s</h4>
        %s</div>',
        esc_html(fam_name), genera_blocks)
    }), collapse="\n")

    if(nchar(trimws(gsub("<[^>]*>","",sections_html)))==0)
      return(tags$p("No photos to display. Upload photos via Record Data \u2192 Photos.",
        style="color:#888;font-style:italic;padding:20px;"))

    n_photos <- nrow(all_photos)
    n_plants <- length(unique(all_photos$plant_id))

    # Inject lightbox overlay + JS photo array + gallery HTML as one raw block
    HTML(paste0(
      # Lightbox overlay
      '<div id="lb-overlay" onclick="if(event.target===this)lbClose()"
            style="display:none;position:fixed;top:0;left:0;width:100%;height:100%;
                   background:rgba(0,0,0,0.88);z-index:9999;
                   justify-content:center;align-items:center;flex-direction:column;">
        <span onclick="lbClose()"
              style="position:fixed;top:18px;right:28px;color:#fff;font-size:36px;
                     cursor:pointer;line-height:1;z-index:10000;">&times;</span>
        <span onclick="lbStep(-1)"
              style="position:fixed;top:50%;left:12px;transform:translateY(-50%);
                     color:#fff;font-size:48px;cursor:pointer;background:rgba(0,0,0,0.3);
                     padding:4px 14px;border-radius:6px;user-select:none;z-index:10000;">&#8249;</span>
        <img id="lb-img" src="" style="max-width:90vw;max-height:80vh;
             border-radius:8px;box-shadow:0 4px 32px #000;">
        <div id="lb-cap" style="color:#eee;font-size:14px;margin-top:12px;
             text-align:center;max-width:80vw;"></div>
        <span onclick="lbStep(1)"
              style="position:fixed;top:50%;right:12px;transform:translateY(-50%);
                     color:#fff;font-size:48px;cursor:pointer;background:rgba(0,0,0,0.3);
                     padding:4px 14px;border-radius:6px;user-select:none;z-index:10000;">&#8250;</span>
      </div>',

      # JS: photo array + functions — all inline, no external escaping
      '<script>',
      'var LB=[', js_objects, '];',
      'var LB_I=0;',
      'function lbOpen(i){',
      '  LB_I=i;',
      '  document.getElementById("lb-img").src=LB[i].src;',
      '  document.getElementById("lb-cap").innerHTML=',
      '    "<strong>"+LB[i].name+"</strong>"+',
      '    (LB[i].cap?"&nbsp;&mdash;&nbsp;"+LB[i].cap:"")+',
      '    "<br><small style=\'color:#aaa\'>"+LB[i].date+"</small>";',
      '  document.getElementById("lb-overlay").style.display="flex";',
      '}',
      'function lbClose(){document.getElementById("lb-overlay").style.display="none";}',
      'function lbStep(d){lbOpen((LB_I+d+LB.length)%LB.length);}',
      'document.onkeydown=function(e){',
      '  if(document.getElementById("lb-overlay").style.display!="flex")return;',
      '  if(e.key==="ArrowRight")lbStep(1);',
      '  if(e.key==="ArrowLeft")lbStep(-1);',
      '  if(e.key==="Escape")lbClose();',
      '};',
      '</script>',

      # Summary line
      sprintf('<p style="color:#555;font-size:13px;margin-bottom:12px;">%d photo%s across %d plant%s</p>',
        n_photos, if(n_photos!=1)"s" else "",
        n_plants, if(n_plants!=1)"s" else ""),

      # Gallery sections
      sections_html
    ))
  })

  # "Jump to plant record" from gallery
  observeEvent(input$gal_goto_plant, {
    updateTabItems(session, "sidebar", "collection")
  })

} # end server

shinyApp(ui=ui, server=server)
