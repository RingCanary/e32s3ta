# AGENTS.md

## Scope
- Repository bootstrap for Waveshare ESP32-S3-LCD-1.28 quick bring-up using MicroPython.
- Keep first-run MicroPython artifacts in `QUICK/`.

## Workflow
- Prefer reproducible commands and scriptable steps.
- Use `uv` for Python tooling and package/runtime execution.
- Do not use `pip` or `requirements.txt`.
- For search/recon tasks, spawn subagents to gather findings in parallel.
- Synthesize subagent findings into repo docs/scripts and record decisions in `WORKLOG.md`.

## Commit Discipline
- Commit at clear checkpoints with descriptive messages.
- Do not squash unrelated work in the same commit.

## Artifacts
- Put firmware binaries under `QUICK/firmware/`.
- Put initial MicroPython code under `QUICK/code/`.
- Keep quick hardware notes/datasheet summaries as Markdown in `QUICK/`.
- Keep non-MicroPython platform docs (Zephyr/RTOS planning/setup) at repo root.
- Track progress in `WORKLOG.md` with epoch-prefixed line items.

## Device Access
- Use `$DEV_DEVICE` as the SSH command for the Raspberry Pi 5 host.
- Run board discovery and flashing from the Pi host where USB is attached.

## Quality Bar
- Verify serial port detection before flashing.
- Record exact firmware version and source URL.
- Provide a minimal on-device display demo as first validation.
