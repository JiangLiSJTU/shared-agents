---
name: mermaid-svg-renderer
description: >
  Expert guide for batch-rendering all Mermaid diagrams embedded in a Markdown
  file into high-quality SVG vector images (transparent background, configurable
  width) using mermaid-cli (mmdc). Use this skill when the user wants to:
  (1) export Mermaid diagrams from Markdown as SVG/PNG for manual insertion into
  PowerPoint, Word, or other tools; (2) batch-process multiple diagrams in one
  shot; (3) automate diagram rendering in a CI or local pipeline.
  Triggers on mentions of "mermaid", "SVG 渲染", "diagram export",
  "mermaid-cli", "mmdc", or "PPT 图表导出".
---

# Mermaid SVG Renderer Skill

## Overview

This skill batch-extracts every ` ```mermaid ` block from a Markdown file and
renders each one into a standalone **SVG vector image** with a transparent
background, ready for direct insertion into PowerPoint (Insert → Picture → SVG).

All rendering is done locally via **mermaid-cli (`mmdc`)**.  
The reusable PowerShell driver is at `scripts/render_mermaid.ps1`.

---

## Prerequisites

### 1. Node.js + npm
Verify with:
```powershell
node --version   # requires v18+
npm --version
```

### 2. mermaid-cli (`mmdc`)
```powershell
npm install -g @mermaid-js/mermaid-cli
mmdc --version   # should print e.g. 11.12.0
```

> **Note:** If `mmdc` is not found by Python `subprocess`, always call it from
> **PowerShell directly** — npm's global bin folder is on the PowerShell PATH
> but may not be inherited by Python child processes on Windows.

---

## Quick Start (copy-paste)

```powershell
# From the directory containing your .md file:
powershell -ExecutionPolicy Bypass -File "C:\Users\leech\VibeCoding\HW\.agents\skills\mermaid-svg-renderer\scripts\render_mermaid.ps1" `
    -MdFile ".\my_slides.md" `
    -OutDir ".\mermaid_svg" `
    -Width 2400 `
    -Background transparent
```

This will:
1. Scan `my_slides.md` for all ` ```mermaid ... ``` ` blocks
2. Render each to `mermaid_svg\diagram_NN.svg` (auto-numbered)
3. Print per-file status and a summary

---

## Script Parameters

| Parameter | Default | Description |
|-----------|---------|-------------|
| `-MdFile` | *(required)* | Path to the source Markdown file |
| `-OutDir` | `.\mermaid_svg` | Output folder (created if missing) |
| `-Width` | `2400` | Render width in pixels (SVG remains vector; affects font/layout scale) |
| `-Background` | `transparent` | Background color: `transparent`, `white`, `#1e1e1e`, etc. |
| `-Labels` | *(auto-number)* | Comma-separated list of output base filenames, in diagram order |

### Using custom labels

```powershell
powershell -ExecutionPolicy Bypass -File "...\render_mermaid.ps1" `
    -MdFile ".\slides.md" `
    -OutDir ".\svg_out" `
    -Labels "intro_flow,arch_overview,timeline"
```

Diagrams beyond the label list fall back to `diagram_NN.svg`.

---

## Agent Workflow

When a user asks to render Mermaid diagrams from a Markdown file, follow these steps:

### Step 1 — Check Prerequisites
```powershell
mmdc --version
```
If command not found, install:
```powershell
npm install -g @mermaid-js/mermaid-cli
```

### Step 2 — Count Diagrams (optional, for labeling)
Open the target Markdown file and search for ` ```mermaid ` blocks.  
Count them so you can prepare meaningful `-Labels` if the user wants named files.

### Step 3 — Prepare Labels (optional)
If slide context is known, derive short snake_case names from each diagram's
slide heading (e.g., `p1_agentic_vs_trad`, `p4_dir2_sandbox`).  
Otherwise, auto-numbering (`diagram_00`, `diagram_01` …) is fine.

### Step 4 — Run the Script
```powershell
powershell -ExecutionPolicy Bypass `
    -File "C:\Users\leech\VibeCoding\HW\.agents\skills\mermaid-svg-renderer\scripts\render_mermaid.ps1" `
    -MdFile "<absolute-path-to-md>" `
    -OutDir "<output-dir>" `
    -Width 2400 `
    -Background transparent `
    [-Labels "label1,label2,..."]
```

### Step 5 — Report Results
After the script finishes, read stdout and report:
- Total diagrams rendered
- Any failures (with error messages)
- Absolute path to the output directory

---

## Common Issues & Fixes

| Symptom | Cause | Fix |
|---------|-------|-----|
| `mmdc not found` in Python | npm global bin not on Python PATH | Call via PowerShell, not Python subprocess |
| `FileNotFoundError` from subprocess | Same as above | Use `powershell -File ...` wrapper |
| SVG renders but text is garbled | Encoding mismatch on Windows | Script uses `[System.IO.File]::ReadAllText(..., UTF8)` — already handled |
| Gantt/sequence diagrams look wrong | mmdc version mismatch | Update: `npm install -g @mermaid-js/mermaid-cli@latest` |
| Long text overflows node box | Node label too wide for default width | Increase `-Width` to 3200 or wrap text with `\n` in the source |
| PS execution policy error | Restricted policy | Add `-ExecutionPolicy Bypass` to the powershell invocation |

---

## Output & PPT Insertion

- Output: one `.svg` per diagram, named by label or `diagram_NN`
- **Transparent background** → overlays cleanly on any slide color
- **In PowerPoint**: Insert → Pictures → select `.svg` file → resize freely without quality loss
- **In Google Slides**: Insert → Image → Upload → `.svg` supported natively

---

## Width Guidelines

| Use case | Recommended `-Width` |
|----------|---------------------|
| Full-slide diagram (16:9) | `2400` – `3200` |
| Half-slide inset | `1600` |
| Small inline figure | `1200` |
| Ultra-high-res print | `4800` |

> Width only affects the internal coordinate system of the SVG;  
> the file remains fully scalable as a vector graphic.

---

## File Locations

```
.agents/skills/mermaid-svg-renderer/
├── SKILL.md                   ← this file
└── scripts/
    └── render_mermaid.ps1     ← reusable PowerShell renderer
```
