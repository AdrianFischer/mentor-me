# Audit and Update Software Inventory

This command audits the CIS software inventory document and updates it to reflect the current state of all software packages built as part of the `build_engine` make target.

## What it does

1. **Identifies build files**: Extracts all Dockerfiles and requirements files used in the `build_engine` target from the Makefile
2. **Checks for changes**: Uses git to determine if any relevant files have changed since the last inventory update
3. **Extracts packages**: Parses Dockerfiles, requirements.txt, and package.json files to extract:
   - System packages (apt install)
   - Python packages (pip install)
   - Node.js packages (npm install)
   - Docker base images
4. **Updates inventory**: If changes are detected, updates the `compliance/security/cis/cis_2-1_software_inventory.md` file with the current software list

## Usage

Simply invoke this command. It will:
- Show which files are being audited
- Indicate if changes are detected
- Update the inventory markdown file if needed
- Preserve existing metadata (publisher, URLs, etc.) where available

## Files audited

The command automatically discovers:
- All Dockerfiles referenced in `build_engine` make target
- All requirements.txt files in:
  - `nys_engine/nys_brain/requirements.txt`
  - `nys_engine/nys_api/requirements.txt`
  - `nys_engine/nys_celery/requirements.txt`
  - `nys_engine/nys_store_db/requirements.txt`
  - `.devcontainer/requirements.txt`
  - `nys_engine/react_storage_ui/requirements.txt`
- All package.json files in:
  - `nys_engine/react_storage_ui/package.json`

## Output

The inventory table in `compliance/security/cis/cis_2-1_software_inventory.md` will be updated with:
- Package titles
- Versions (extracted from files)
- Deployment mechanisms
- File references (links to the source files where each package is mentioned)
- Last updated date

The inventory is maintained in canonical order (case-insensitive alphabetical by title) to minimize file diff churn when packages are added, removed, or updated.

The File References column contains markdown links to the source files (Dockerfiles, requirements.txt, or package.json) where each software package is defined. Multiple files are listed when a package appears in multiple locations.

Note: Publisher, URL, and business purpose fields may need manual review/update as the script uses heuristics to populate these fields.

