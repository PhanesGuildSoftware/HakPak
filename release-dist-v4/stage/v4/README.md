# HakPak4

HakPak4 is the next major generation of HakPak. This directory is a standalone v4 runtime scaffold derived from v3 so development can proceed without destabilizing current v3 release packaging.

## Current Version

- Defined in `VERSION` (single source of truth)

## Included v4 Runtime Files

- `hakpak4.py`: shared models, detection, and UI helpers
- `hakpak4_core.py`: install logic, menu flow, and CLI entrypoint
- `hakpak4.sh`: shell launcher
- `install-hakpak4.sh`: system installer (`/opt/hakpak4`, `/usr/local/bin/hakpak4`)
- `test-hakpak4.sh`: baseline smoke tests
- `kali-tools-db.yaml`: tool database (currently synced from v3)

## Quick Start (Dev)

```bash
cd v4
python3 hakpak4_core.py --version
sudo bash hakpak4.sh
```

## System Install (Dev)

```bash
cd v4
sudo bash install-hakpak4.sh
hakpak4 --version
```

## Notes

- This is an initial scaffold to begin v4 work quickly.
- v3 and v4 can coexist because install roots and command names are distinct.
- Release scripts at repository root are still v3-oriented and have not been switched to v4 yet.

## Build v4 Release Artifact

```bash
bash scripts/build-dist-v4.sh
```

Outputs are written to `release-dist-v4/`.

## Immediate Next Steps

1. Define v4 feature delta versus v3.
2. Add/adjust tests for new behavior in `test-hakpak4.sh` and Python unit tests.
3. Introduce v4 release pipeline updates once runtime changes stabilize.
