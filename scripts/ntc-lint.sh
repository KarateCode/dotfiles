#!/bin/zsh

set -u

has_script() {
    node -e '
        const fs = require("fs");
        try {
            const p = JSON.parse(fs.readFileSync("package.json", "utf8"));
            process.exit(p.scripts && p.scripts[process.argv[1]] ? 0 : 1);
        } catch { process.exit(1); }
    ' "$1" 2>/dev/null
}

if [[ ! -f package.json ]]; then
    print -u2 "ntc-lint: no package.json in $PWD"
    exit 2
fi

# Explicit opt-out: run exactly what CI runs.
if [[ "${NTC_LINT_FULL:-0}" == "1" ]]; then
    print "ntc-lint: NTC_LINT_FULL=1 -- running the full upstream 'lint'"
    exec npm run lint
fi

# If the project has adopted its own trimmed script, defer to it entirely.
if has_script lint:local; then
    print "ntc-lint: using the project's own 'lint:local'"
    exec npm run lint:local
fi

# Not a repo we recognise -- do not silently lint less than the user asked for.
if ! has_script lint:less || ! has_script check:node-sync; then
    print "ntc-lint: unfamiliar project layout, falling back to 'npm run lint'"
    exec npm run lint
fi

print "ntc-lint: skipping mobile:lint and build:server (see script header)"
print "          type coverage preserved via tsc --noEmit"
print ""

# `npx` rather than ./node_modules/.bin/... so this still resolves when the
# pane was opened in a subdirectory of the project.
ESLINT_USE_FLAT_CONFIG=false npx --no-install eslint \
    --cache --cache-location node_modules/.cache/eslint/all \
    . --ext .js,.mjs,.ts,.tsx \
  && npm run lint:less \
  && npm run check:node-sync \
  && npx --no-install tsc --noEmit
