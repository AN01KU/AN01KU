#!/usr/bin/env bash
# Build README.md from README.template.md and a shared-config checkout.
# Usage: build-readme.sh <shared-config-dir>
set -euo pipefail

CONFIG_DIR="${1:?Usage: build-readme.sh <shared-config-dir>}"
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TEMPLATE="${ROOT}/README.template.md"
OUTPUT="${ROOT}/README.md"
TMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TMP_DIR"' EXIT

if [[ ! -f "$TEMPLATE" ]]; then
  echo "README.template.md not found at: $TEMPLATE" >&2
  exit 1
fi

if [[ ! -d "${CONFIG_DIR}/data" || ! -f "${CONFIG_DIR}/profile.env" ]]; then
  echo "shared-config not found at: ${CONFIG_DIR}" >&2
  exit 1
fi

if ! command -v jq >/dev/null 2>&1; then
  echo "jq is required" >&2
  exit 1
fi

SITE_CONFIG="${TMP_DIR}/site-config.json"
bash "${CONFIG_DIR}/scripts/build-site-config.sh" "$CONFIG_DIR" "$SITE_CONFIG"

FULL_NAME="$(jq -r '.profile.fullName' "$SITE_CONFIG")"
TITLE="$(jq -r '.profile.title' "$SITE_CONFIG")"
COMPANY="$(jq -r '.profile.company' "$SITE_CONFIG")"
COMPANY_URL="$(jq -r '.profile.companyUrl' "$SITE_CONFIG")"
EMAIL="$(jq -r '.profile.email' "$SITE_CONFIG")"
PORTFOLIO_URL="$(jq -r '.social.portfolioUrl' "$SITE_CONFIG")"
LINKEDIN_URL="$(jq -r '.social.linkedinUrl' "$SITE_CONFIG")"
LEETCODE_URL="$(jq -r '.social.leetcodeUrl' "$SITE_CONFIG")"

PUBLICATIONS="${CONFIG_DIR}/data/publications.json"
EDUCATION="${CONFIG_DIR}/data/education.json"
SKILLS="${CONFIG_DIR}/data/skills.json"

PUBLICATION_TITLE="$(jq -r '.publications[0].title // empty' "$PUBLICATIONS")"
PUBLICATION_URL="$(jq -r '.publications[0].url // empty' "$PUBLICATIONS")"

EDUCATION_DEGREE="$(jq -r '.education[] | select(.id == "btech-cs") | .degree' "$EDUCATION")"
EDUCATION_INSTITUTION="$(jq -r '.education[] | select(.id == "btech-cs") | .institution' "$EDUCATION")"
EDUCATION_CITY="$(jq -r '.education[] | select(.id == "btech-cs") | .location | split(",")[0]' "$EDUCATION")"
EDUCATION_START="$(jq -r '.education[] | select(.id == "btech-cs") | .startYear' "$EDUCATION")"
EDUCATION_END="$(jq -r '.education[] | select(.id == "btech-cs") | .endYear' "$EDUCATION")"
EDUCATION_YEARS="${EDUCATION_START}–${EDUCATION_END}"

SKILLS_BLOCK="${TMP_DIR}/skills-block.txt"
# Profile README shows a subset of skills.json (portfolio uses all categories).
jq -r '
  ["languages", "core-subjects", "backend-infra"] as $order |
  $order[] as $id |
  .categories[] | select(.id == $id) |
  "- **\(.name):** " + (.items | join(" · "))
' "$SKILLS" > "$SKILLS_BLOCK"

escape_sed() {
  printf '%s' "$1" | sed -e 's/[\/&]/\\&/g'
}

substitute_line() {
  local line="$1"
  local key="$2"
  local value="$3"
  local escaped
  escaped="$(escape_sed "$value")"
  printf '%s' "$line" | sed "s|{{${key}}}|${escaped}|g"
}

declare -A VALUES=(
  [FULL_NAME]="$FULL_NAME"
  [TITLE]="$TITLE"
  [COMPANY]="$COMPANY"
  [COMPANY_URL]="$COMPANY_URL"
  [EMAIL]="$EMAIL"
  [PORTFOLIO_URL]="$PORTFOLIO_URL"
  [LINKEDIN_URL]="$LINKEDIN_URL"
  [LEETCODE_URL]="$LEETCODE_URL"
  [PUBLICATION_TITLE]="$PUBLICATION_TITLE"
  [PUBLICATION_URL]="$PUBLICATION_URL"
  [EDUCATION_DEGREE]="$EDUCATION_DEGREE"
  [EDUCATION_INSTITUTION]="$EDUCATION_INSTITUTION"
  [EDUCATION_CITY]="$EDUCATION_CITY"
  [EDUCATION_YEARS]="$EDUCATION_YEARS"
)

{
  while IFS= read -r line || [[ -n "$line" ]]; do
    [[ "$line" =~ ^\<!--.*--\>$ ]] && continue

    if [[ "$line" == "{{CORE_EXPERTISE}}" ]]; then
      cat "$SKILLS_BLOCK"
      continue
    fi

    for key in FULL_NAME TITLE COMPANY COMPANY_URL EMAIL PORTFOLIO_URL LINKEDIN_URL LEETCODE_URL \
      PUBLICATION_TITLE PUBLICATION_URL \
      EDUCATION_DEGREE EDUCATION_INSTITUTION EDUCATION_CITY EDUCATION_YEARS
    do
      if [[ "$line" == *"{{${key}}}"* ]]; then
        line="$(substitute_line "$line" "$key" "${VALUES[$key]}")"
      fi
    done

    printf '%s\n' "$line"
  done < "$TEMPLATE"
} > "$OUTPUT"

if grep -q '{{[A-Z_]*}}' "$OUTPUT"; then
  echo "Unresolved placeholders remain in README output:" >&2
  grep -o '{{[A-Z_]*}}' "$OUTPUT" | sort -u >&2
  exit 1
fi

echo "Built ${OUTPUT} from shared-config at ${CONFIG_DIR}"
