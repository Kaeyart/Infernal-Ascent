# Infernal Ascent Hub Asset Pipeline V1

This package turns the two generated hub sheets into usable transparent PNG assets.

It already includes the current cleaned and sliced output from the two sheets you uploaded.

## Folders

```text
art/hub_generated/source/
art/hub_generated/sliced/
art/hub_generated/contact_sheets/
art/hub_generated/manifest/
tools/hub_asset_pipeline/
```

## The important files

```text
art/hub_generated/contact_sheets/ALL_ASSETS_CONTACT_SHEET.png
art/hub_generated/manifest/ia_hub_assets_manifest.csv
art/hub_generated/manifest/ia_hub_assets_manifest.json
```

Open the contact sheet first. It shows the sliced assets with filenames.

## Re-run the slicer later

From the project root:

```bash
python3 tools/hub_asset_pipeline/ia_prepare_hub_assets.py   --structural art/hub_generated/source/ia_hub_structural_sheet.png   --props art/hub_generated/source/ia_hub_props_sheet.png
```

## Important

This does not edit the hub scene. It only prepares the source art so the next patch can rebuild the hub using selected filenames.

Do not try to use every sliced object. The next step should be a curated hub pack: choose the cleanest floors, walls, props, and landmarks from the contact sheets.
