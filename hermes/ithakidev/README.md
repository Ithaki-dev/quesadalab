# Hermes: IthakiDev business profile

This workspace defines the operating profile material for Hermes when assisting
with IthakiDev work.

## Purpose

Use this profile when the task is related to:

- `ithakidev.com`
- client communication
- business operations
- service packaging
- content planning
- product/service strategy
- website and infrastructure decisions for IthakiDev

Hermes should treat this as a business workspace, not as the QuesadaLab homelab
operations workspace.

## Install on agent01

Copy this folder to the Hermes workspace directory:

```bash
mkdir -p /home/hermes/.hermes/workspaces/ithakidev
scp -r hermes/ithakidev/* hermes@192.168.1.60:/home/hermes/.hermes/workspaces/ithakidev/
```

Then protect the files:

```bash
chown -R hermes:hermes /home/hermes/.hermes/workspaces/ithakidev
find /home/hermes/.hermes/workspaces/ithakidev -type d -exec chmod 700 {} \;
find /home/hermes/.hermes/workspaces/ithakidev -type f -exec chmod 600 {} \;
```

Create the dedicated IthakiDev memory section inside the Hermes Obsidian vault:

```bash
bash /home/hermes/.hermes/obsidian-ithakidev-setup.sh /home/hermes/.hermes/obsidian
find /home/hermes/.hermes/obsidian/ithakidev -type d -exec chmod 700 {} \;
find /home/hermes/.hermes/obsidian/ithakidev -type f -exec chmod 600 {} \;
```

## Usage

When starting an IthakiDev task, tell Hermes:

```text
Trabaja en /home/hermes/.hermes/workspaces/ithakidev.
Lee profile.md y operating-prompt.md antes de responder.
```

For task completion, use the Obsidian post-task hook:

```bash
HERMES_MEMORY_SECTION=ithakidev \
  bash /home/hermes/.hermes/hermes-post-task-hook.sh "Completed IthakiDev task: <summary>"
```

The IthakiDev memory section lives at:

```text
/home/hermes/.hermes/obsidian/ithakidev
```

## Create the Hermes profile

Create a real Hermes profile so IthakiDev has isolated config, sessions, memory,
skills, and gateway state:

```bash
hermes profile create ithakidev \
  --clone \
  --description "IthakiDev business assistant for client work, service planning, documentation, and business operations."

ithakidev config set terminal.cwd /home/hermes/.hermes/workspaces/ithakidev

cp /home/hermes/.hermes/workspaces/ithakidev/operating-prompt.md \
  /home/hermes/.hermes/profiles/ithakidev/SOUL.md

chmod 600 /home/hermes/.hermes/profiles/ithakidev/SOUL.md
```

Validate:

```bash
ithakidev profile
ithakidev chat -q "Lee tu perfil IthakiDev y responde solo ITHAKIDEV_PROFILE_OK"
```

## Data rules

Do not store secrets in this workspace.

Keep these outside Git and only in private credential stores:

- client credentials
- API keys
- hosting credentials
- payment data
- private client documents
- passwords
- recovery codes
