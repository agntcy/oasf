#!/usr/bin/env bash
set -euo pipefail
# generate_trivy_summary.sh
# Reads Trivy SARIF artifacts and appends a Markdown table to $GITHUB_STEP_SUMMARY.

if [[ -z "${GITHUB_STEP_SUMMARY:-}" ]]; then
  echo "GITHUB_STEP_SUMMARY not set; aborting." >&2
  exit 1
fi

echo '## Container Security Scan Summary' >> "$GITHUB_STEP_SUMMARY"
echo '' >> "$GITHUB_STEP_SUMMARY"

files=$(ls trivy-artifacts/*/trivy-*.sarif 2>/dev/null || true)
if [[ -z "$files" ]]; then
  echo 'No SARIF files found in artifacts (check previous job logs).' >> "$GITHUB_STEP_SUMMARY"
  exit 0
fi

echo '| Image | Critical | High | Medium | Total | File |' >> "$GITHUB_STEP_SUMMARY"
echo '|-------|----------|------|--------|-------|------|' >> "$GITHUB_STEP_SUMMARY"

for f in $files; do
  img=$(basename "$f" .sarif | sed 's/^trivy-//')
  critical=$(jq -r '.runs[] as $run | [ $run.results[] | select(($run.tool.driver.rules[.ruleIndex].properties.tags // []) | index("CRITICAL")) ] | length' "$f" 2>/dev/null || echo 0)
  high=$(jq -r '.runs[] as $run | [ $run.results[] | select(($run.tool.driver.rules[.ruleIndex].properties.tags // []) | index("HIGH")) ] | length' "$f" 2>/dev/null || echo 0)
  medium=$(jq -r '.runs[] as $run | [ $run.results[] | select(($run.tool.driver.rules[.ruleIndex].properties.tags // []) | index("MEDIUM")) ] | length' "$f" 2>/dev/null || echo 0)
  total=$(jq -r '[.runs[].results[]] | length' "$f" 2>/dev/null || echo 0)
  echo "| $img | $critical | $high | $medium | $total | $(basename "$f") |" >> "$GITHUB_STEP_SUMMARY"
done

echo '' >> "$GITHUB_STEP_SUMMARY"
echo 'Severity counts derived from rule tags (CRITICAL/HIGH/MEDIUM) mapped via result.ruleIndex.' >> "$GITHUB_STEP_SUMMARY"
