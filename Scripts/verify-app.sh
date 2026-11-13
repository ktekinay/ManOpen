#!/bin/sh
#
# verify-app.sh - check a built ManOpen.app before release.
#
# Usage: Scripts/verify-app.sh path/to/ManOpen.app
#
# Checks that every executable is universal (arm64 and x86_64) and signed
# with Hardened Runtime, that the openman tool and its man page are inside the
# app, and that the app passes a strict signature check. Exits non-zero and
# lists the problems if anything fails.

set -u

app="${1:-}"
if [ -z "$app" ] || [ ! -d "$app" ]; then
    echo "usage: $0 path/to/ManOpen.app" >&2
    exit 2
fi

problems=0
fail() {
    echo "FAIL: $*" >&2
    problems=$((problems + 1))
}

executables="
Contents/MacOS/ManOpen
Contents/Helpers/openman
Contents/Resources/cat2rtf
Contents/Resources/cat2html
"

for relative in $executables; do
    file="$app/$relative"
    if [ ! -x "$file" ]; then
        fail "missing or not executable: $relative"
        continue
    fi

    archs=$(lipo -archs "$file" 2>/dev/null)
    case " $archs " in
        *" arm64 "*) ;;
        *) fail "$relative is not built for arm64 (has: $archs)" ;;
    esac
    case " $archs " in
        *" x86_64 "*) ;;
        *) fail "$relative is not built for x86_64 (has: $archs)" ;;
    esac

    if ! codesign -dv "$file" 2>&1 | grep -q "flags=.*runtime"; then
        fail "$relative is not signed with Hardened Runtime"
    fi
done

if [ ! -f "$app/Contents/Resources/man/man1/openman.1" ]; then
    fail "missing Contents/Resources/man/man1/openman.1"
fi

if ! codesign --verify --deep --strict "$app" 2>/dev/null; then
    fail "codesign --verify --deep --strict failed"
fi

if [ "$problems" -gt 0 ]; then
    echo "$problems problem(s) found in $app" >&2
    exit 1
fi

echo "OK: $app"
