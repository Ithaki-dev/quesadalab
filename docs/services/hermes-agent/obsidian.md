# Obsidian for Hermes and Personal Use

This document defines the Obsidian strategy for QuesadaLab.

## Goals

- Use Obsidian for personal notes, project notes, and lab documentation.
- Use a separate Hermes memory vault so the agent can retain curated context.
- Keep personal notes and agent memory separated.
- Avoid placing secrets, tokens, or raw credentials in the Git repository.

## Recommended layout

Use two vaults:

- Personal vault: your private Obsidian workspace for daily notes and project notes.
- Hermes vault: a separate vault used by Hermes as long-term memory and operational notes.

Suggested paths:

```text
/opt/quesadalab/data/obsidian/personal
/home/hermes/.hermes/obsidian
```

If you prefer local-only storage on your laptop, keep the personal vault in your own user profile and only keep the Hermes vault on `agent01`.

## Why separate them

- Personal notes can be edited freely in Obsidian.
- Hermes memory should be constrained to curated, agent-safe notes.
- Agent memory should never contain passwords, API keys, bot tokens, recovery codes, or full secrets.

## Hermes memory model

Hermes should not treat Obsidian as a free-form scratchpad. It should use it as a structured memory store with a small set of note types:

- `00-inbox.md` for newly observed facts that still need review.
- `10-profile.md` for stable personal and project facts.
- `20-projects.md` for active work and current goals.
- `30-operations.md` for operational notes and incident summaries.
- `90-archive.md` for old context that is no longer active.

Keep each note concise and factual.

## Suggested Hermes memory workflow

1. Hermes writes a short draft to `00-inbox.md`.
2. You review and promote only the useful facts into `10-profile.md`, `20-projects.md`, or `30-operations.md`.
3. Hermes reads only the approved notes, not raw chat logs.
4. Secrets stay in `.env`, password managers, or private credential stores, never in Obsidian.

## Minimal vault structure

Personal vault:

```text
personal/
  Daily/
  Projects/
  Reference/
  Templates/
  Attachments/
```

Hermes vault:

```text
hermes/
  00-inbox.md
  10-profile.md
  20-projects.md
  30-operations.md
  90-archive.md
  attachments/
  templates/
```

## What Hermes may store

- Stable project names.
- System IPs and hostnames.
- Approved runbooks and operational reminders.
- Non-secret workflow notes.
- Short summaries of completed incidents.

## What Hermes must not store

- Passwords.
- API keys.
- Bot tokens.
- Recovery codes.
- Private keys.
- Full vault exports.
- Raw logs with secrets.

## Recommended implementation

1. Create the personal vault where you already keep notes.
2. Create the Hermes vault on `agent01`.
3. Add a small script that seeds the Hermes vault structure.
4. Add a second script or cron task later if you want Hermes to write approved summaries automatically.

## Validation

Check that the vaults exist and are separate:

```bash
test -d /opt/quesadalab/data/obsidian/personal
test -d /home/hermes/.hermes/obsidian
```

Check that no secrets live in the vault structure:

```bash
grep -RIn --exclude-dir=.git --exclude='*.png' --exclude='*.jpg' \
  -E 'API_KEY|TOKEN|PASSWORD|SECRET' \
  /opt/quesadalab/data/obsidian/personal /home/hermes/.hermes/obsidian
```

## Notes

- Obsidian itself is just the editor.
- The important part is the vault layout and the discipline around what Hermes is allowed to write.
- If you later want sync across devices, add it as a separate layer after the vault structure is stable.

