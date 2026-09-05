# GitHub profile README — shared-config sync

`README.md` is generated from `README.template.md` plus private [shared-config](https://github.com/AN01KU/shared-config). Edit the template for local-only content (bio, experience bullets, tagline), then sync shared values from `shared-config`.

## What comes from shared-config

| Placeholder | Source |
|-------------|--------|
| Name, title, company, email | `profile.env` → `site-config.json` |
| Portfolio, LinkedIn, LeetCode links | `social.env` → `site-config.json` |
| Core Expertise section | `data/skills.json` (`languages`, `core-subjects`, `backend-infra` only) |
| Hobbies | `data/hobbies.json` |
| Publication title, URL, description | `data/publications.json` |
| Education (B.Tech entry) | `data/education.json` (`id: btech-cs`) |

**Stays in `README.template.md`:** bio, work experience bullets and dates.

## Local refresh

Clone `shared-config` next to this repo, then:

```bash
bash scripts/sync-shared-config.sh

# Or set a custom path
SHARED_CONFIG_DIR=/path/to/shared-config bash scripts/sync-shared-config.sh
```

Requires `bash` and `jq`.

## GitHub setup

Add secret **`SHARED_CONFIG_TOKEN`**: fine-grained PAT with **Contents: Read** on `shared-config`.

The **Sync README** workflow checks out `shared-config`, rebuilds `README.md`, and commits if anything changed. Run it manually after updating `shared-config`, or let the weekly schedule pick it up.
