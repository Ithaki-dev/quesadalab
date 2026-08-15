# Obsidian Setup

This runbook defines a safe way to introduce Obsidian for QuesadaLab.

## Scope

- Personal Obsidian vault for your own notes.
- Hermes Obsidian vault for structured memory.
- No secrets in Git.
- No automatic sync until the vault layout is stable.

## Recommended vaults

Personal:

```text
/opt/quesadalab/data/obsidian/personal
```

Hermes:

```text
/home/hermes/.hermes/obsidian
```

## Recommended sync model

Use the personal vault as the only synced vault. Keep Hermes memory local on
`agent01` and export only approved summaries into the personal vault.

Recommended arrangement:

- Personal vault sync: Obsidian Sync
- Hermes vault: local only, no direct sync
- Hermes export target: a dedicated folder inside the personal vault

Suggested personal vault export folder:

```text
/opt/quesadalab/data/obsidian/personal/Imported-from-Hermes
```

Do not sync the Hermes vault itself. That would mix agent memory with your
private working notes and increases the risk of leaking operational context.

## Obsidian Sync setup

Obsidian stores notes locally in vault folders and uses a remote vault for
sync. Create one remote vault for your personal notes and connect your local
devices to it.

Suggested first-device flow:

1. Open Obsidian on your personal machine.
2. Sign in to your Obsidian account.
3. Enable the Sync core plugin.
4. Create a new remote vault.
5. Pick or create your personal local vault folder.
6. Use end-to-end encryption for the remote vault.
7. Start syncing after reviewing selective sync settings.

Important rules:

- Do not pair the same vault with Obsidian Sync and another sync system.
- Keep the Hermes vault outside Obsidian Sync.
- Use selective sync if you want to exclude large or device-specific folders.
- Treat the sync service as transport, not as your only backup.

For a second device:

1. Open Obsidian.
2. Sign in to the same Obsidian account.
3. Enable Sync.
4. Connect to the existing remote vault.
5. Confirm encryption password.
6. Adjust selective sync settings before resuming sync.

## Hermes vault structure

```text
00-inbox.md
10-profile.md
20-projects.md
30-operations.md
90-archive.md
attachments/
templates/
```

## Bootstrap Hermes vault

On `agent01`:

```bash
cd /opt/quesadalab-repo
bash scripts/obsidian-setup.sh /home/hermes/.hermes/obsidian
chown -R hermes:hermes /home/hermes/.hermes/obsidian
find /home/hermes/.hermes/obsidian -type d -exec chmod 700 {} \;
find /home/hermes/.hermes/obsidian -type f -exec chmod 600 {} \;
```

## Personal vault guidance

For your personal vault:

- keep it outside Git unless you intentionally publish non-sensitive notes;
- separate daily notes from project notes;
- store attachments in a dedicated folder;
- avoid mixing personal secrets with Hermes memory.

## Hermes memory workflow

1. Hermes records short notes in `00-inbox.md`.
2. You review and promote stable facts into `10-profile.md`, `20-projects.md`, or `30-operations.md`.
3. Hermes reads only approved notes.
4. Do not store passwords, API keys, recovery codes, or private keys.
5. Export only curated summaries from Hermes into the personal vault.

## Export workflow

Use a local export script on `agent01` to generate a dated markdown summary from
approved Hermes notes.

The export should:

- include only non-secret operational summaries;
- exclude raw chat logs and credentials;
- write into the personal vault export folder;
- preserve the Hermes vault as the source of truth for agent memory.

Example export target:

```text
/opt/quesadalab/data/obsidian/personal/Imported-from-Hermes/hermes-summary-YYYY-MM-DD.md
```

## Validation

```bash
test -d /home/hermes/.hermes/obsidian
test -f /home/hermes/.hermes/obsidian/00-inbox.md
test -f /home/hermes/.hermes/obsidian/10-profile.md
test -f /home/hermes/.hermes/obsidian/20-projects.md
test -f /home/hermes/.hermes/obsidian/30-operations.md
test -f /home/hermes/.hermes/obsidian/90-archive.md
```

## Future sync options

If you later want a different multi-device sync model, replace Obsidian Sync as
a conscious migration. Do not run two sync systems against the same vault.

## Backup policy

Yes, both vaults should be part of the backup plan, but with different rules.

### Personal vault

- Include in the normal homelab backup strategy.
- Treat as user data.
- Restore it independently from Hermes if needed.
- Keep the synced copy and the backup copy separate concepts.

### Hermes vault

- Include in the Hermes VM backup and recovery plan.
- Treat as operational memory with a higher confidentiality level.
- Back it up together with the rest of `/home/hermes/.hermes`.
- Never export it to shared storage in raw form unless the data is curated and approved.

### Backup guidance

- Back up before changing the vault taxonomy, sync layout, or export workflow.
- Validate that backups can be restored.
- Do not rely on Obsidian Sync as your only backup.
- Keep secrets out of vault content so the backups remain safe to handle.
