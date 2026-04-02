---
name: pptx-diagram-inserter
description: >
  Expert tool for automating the insertion of diagrams (like PNG, JPEG) into specific slides of a PowerPoint (PPTX) presentation. Handles aspect-ratio-preserving scaling, horizontal centering, and vertical positioning intelligently (avoids overlapping intelligently if an existing image like a Gamma AI picture is already present on the slide). Ideal for integrating exported Mermaid/PlantUML diagrams or AI-generated graphs into Gamma presentations or manually curated PPTX files.
  Triggers on mentions of "PPT插入图表", "PPT图片排版", "将图片插入PPT", "insert diagrams to ppt".
---

# PPTX Diagram Inserter Skill

## Overview

This skill simplifies the tedious process of manually inserting numerous exported diagrams into a PowerPoint presentation. It allows programmatic insertion by defining a mapping between slide index (1-based) and the path to the corresponding diagram file.

This is extremely helpful when used in combination with skills like `mermaid-svg-renderer` and `gamma-ppt-generator`.

---

## Capabilities

The `insert_diagrams.py` script automatically:
1. **Preserves Aspect Ratio:** Scales your image to be as large as possible without exceeding the defined bounding box.
2. **Smart Vertical Placement:** Automatically detects if a slide already has picture elements (e.g., from Gamma AI) and places your diagram below those existing elements. For text-only slides, it centers the diagram higher in the slide's body.
3. **Boundary Clamping:** Ensures diagrams don't overflow the bottom edge of the slide frame.

---

## Quick Start 

### 1. Requirements

Ensure `python-pptx` and `Pillow` are installed:
```powershell
pip install python-pptx Pillow
```

### 2. Prepare the Mapping

Create a JSON mapping defining which image goes on which slide. The keys MUST be the 1-based slide index integers formatted as strings. You can either pass this inline as a JSON string, or specify a path to a JSON file.

Example JSON (`map.json`):
```json
{
    "3": "mermaid_png\\p1_agentic_vs_trad.png",
    "4": "mermaid_png\\p1_three_challenges.png",
    "21": "mermaid_png\\p5_roadmap_gantt.png"
}
```

### 3. Run the Tool

Use the CLI script to execute the insertion. Make sure to specify the layout parameters if you are not using standard 16:9 slides.

```powershell
python "C:\Users\leech\VibeCoding\.agents\skills\pptx-diagram-inserter\scripts\insert_diagrams.py" `
    --in-pptx "Source.pptx" `
    --out-pptx "Output.pptx" `
    --map map.json
```

---

## Agent / Assistant Workflow

When a user asks to insert images or diagrams into a PPT, follow these steps:

### Step 1: Discover Slide Map
Determine *which* slide number receives *which* image.
- If the original markdown has `---` delimitations separating slides, you can quickly write a tiny python script (`scan_md.py`) to count how many `---` appear before a specific ` ```mermaid ` block starts. This will give you the precise PPT slide number.
- Alternatively, if the user explicitly tells you the names of the images and the slides they belong to, assemble that as a JSON dictionary string.

### Step 2: Extract PPTX Configuration
Confirm the dimensions of the user's PPTX. The defaults in the script are targeted for standard 16:9 (16" x 9" sizes).
If the user's PPT is different or spacing is constrained, adjust these command line flags:
- `--max-width` (default 14.8)
- `--max-height` (default 5.0)
- `--top-with-img` (default 3.8 inches down if an image exists)
- `--top-no-img` (default 2.3 inches down if no image exists)

### Step 3: Run the command
Inject the JSON inline to avoid creating unnecessary temporary files (if the map is small):
```powershell
python "C:\Users\leech\VibeCoding\.agents\skills\pptx-diagram-inserter\scripts\insert_diagrams.py" `
    --in-pptx "presentation.pptx" `
    --out-pptx "presentation_with_diagrams.pptx" `
    --map '{"3": "test.png"}'
```

### Step 4: Verification
The python script will output exactly which slides were patched successfully, dimensions, and skipped elements. Forward this summary to the user.

---

## File Locations

```
.agents/skills/pptx-diagram-inserter/
├── SKILL.md                   ← this file
└── scripts/
    └── insert_diagrams.py     ← the generic python script
```
