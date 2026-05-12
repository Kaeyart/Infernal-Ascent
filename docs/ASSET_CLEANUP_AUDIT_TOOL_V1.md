# Infernal Ascent — Asset Cleanup Audit V1

This adds a safe cleanup tool for unused art.

It does not delete anything by default. The intended flow is:

1. audit
2. quarantine unused runtime art
3. test the game
4. only then delete the quarantine

## Install

```bash
cd /home/kaey/Downloads/infernal_ascent_iso_v2 || exit 1
unzip -o /home/kaey/Downloads/infernal_ascent_asset_cleanup_audit_v1_patch.zip
```

## Audit

```bash
python3 tools/ia_asset_cleanup_audit.py audit
```

This writes:

```text
docs/ASSET_CLEANUP_AUDIT_V1.md
docs/ASSET_CLEANUP_AUDIT_V1.json
docs/ASSET_CLEANUP_UNUSED_CANDIDATES_V1.csv
```

## Quarantine unused runtime art

```bash
python3 tools/ia_asset_cleanup_audit.py quarantine --apply
```

This moves unused runtime art to:

```text
_quarantine_unused_art/
```

It also moves `.import` companions.

## Restore if something breaks

```bash
python3 tools/ia_asset_cleanup_audit.py restore --manifest _quarantine_unused_art/<folder>/RESTORE_MANIFEST.json --apply
```

## Permanently delete quarantine later

Only after the hub and run room still work:

```bash
python3 tools/ia_asset_cleanup_audit.py delete-quarantine --apply
```

## Production source sheets

By default, source sheets/contact sheets/manifests are reported separately but not quarantined. To include them:

```bash
python3 tools/ia_asset_cleanup_audit.py quarantine --include-production-sources --apply
```
