#!/usr/bin/env bash
# Run tests using the branch URL from .env (post-checkout hook writes it).
# Detects project language and calls the appropriate test runner.
# Usage: ./scripts/run-tests.sh [extra args]
#
# E2E-ASSEMBLY CONTRACT (kit maintainers): this template is intentionally
# BLOCK-LESS for the Playwright E2E suite. The E2E block is NOT shipped inline
# here; scm-utils' `enableE2eForProject` / `addE2eToRunTestsScript` APPENDS it
# per-project at scaffold/upgrade time (idempotent; delimited by the marker
# `
# run Playwright E2E suite when configured
if [ -z "${E2E_BACKEND_PORT:-}" ] && [ -f "$REPO_ROOT/scripts/port-utils.sh" ]; then
  # shellcheck source=/dev/null
  source "$REPO_ROOT/scripts/port-utils.sh"
  export E2E_BACKEND_PORT="$(free_port 8000)"
  export E2E_CLIENT_PORT="$(free_port 5173)"
  export VITE_PROXY_TARGET="http://127.0.0.1:${E2E_BACKEND_PORT}"
  echo "Local E2E free-port: backend :$E2E_BACKEND_PORT / client :$E2E_CLIENT_PORT"
fi
if [ -z "${BASE_URL:-}" ] && command -v lsof >/dev/null 2>&1; then
  for p in "${E2E_BACKEND_PORT:-8000}" "${E2E_CLIENT_PORT:-5173}"; do
    if lsof -iTCP:"$p" -sTCP:LISTEN -n -P >/dev/null 2>&1; then
      echo "Local E2E: clearing a stale listener on :$p before the webServer boot"
      lsof -ti tcp:"$p" 2>/dev/null | xargs kill 2>/dev/null || true
    fi
  done
fi
if [ -f "$REPO_ROOT/playwright.config.ts" ] || [ -f "$REPO_ROOT/playwright.config.js" ]; then
  echo "Running Playwright E2E tests..."
  if [ -f "$REPO_ROOT/package.json" ] && command -v npm >/dev/null 2>&1; then
    (cd "$REPO_ROOT" && CI=1 npm run test:e2e)
  else
    (cd "$REPO_ROOT" && CI=1 npx --yes playwright test)
  fi
elif [ -f "$REPO_ROOT/tests/e2e/conftest.py" ] && [ -f "$REPO_ROOT/pyproject.toml" ]; then
  echo "Running Python E2E tests (pytest tests/e2e)..."
  (cd "$REPO_ROOT" && uv run --extra dev playwright install chromium)
  set +e
  (cd "$REPO_ROOT" && uv run --extra dev pytest tests/e2e)
  e2e_rc=$?
  set -e
  if [ "$e2e_rc" -ne 0 ] && [ "$e2e_rc" -ne 5 ]; then exit "$e2e_rc"; fi
fi

# run client Playwright E2E suite when configured
if [ -f "$REPO_ROOT/client/playwright.config.ts" ] || [ -f "$REPO_ROOT/client/playwright.config.js" ] || [ -f "$REPO_ROOT/client/playwright.config.mjs" ]; then
  echo "Running client Playwright E2E tests..."
  (cd "$REPO_ROOT/client" && npx --yes playwright install chromium)
  (cd "$REPO_ROOT/client" && CI=1 npx --yes playwright test --pass-with-no-tests)
fi
