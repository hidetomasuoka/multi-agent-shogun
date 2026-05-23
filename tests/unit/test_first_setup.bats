#!/usr/bin/env bats

setup() {
    TEST_TMP="$(mktemp -d)"
    REPO_ROOT="$(cd "$(dirname "$BATS_TEST_FILENAME")/../.." && pwd)"
    TEST_HOME="$TEST_TMP/home"
    TEST_BIN="$TEST_TMP/bin"
    TEST_PROJECT="$TEST_TMP/project"

    mkdir -p "$TEST_HOME" "$TEST_BIN" "$TEST_PROJECT/memory" "$TEST_PROJECT/scripts" \
        "$TEST_PROJECT/skills/sample-skill" "$TEST_PROJECT/.venv/bin"

    cp "$REPO_ROOT/first_setup.sh" "$TEST_PROJECT/first_setup.sh"
    echo "# sample memory" > "$TEST_PROJECT/memory/MEMORY.md.sample"
    echo "print('dashboard viewer stub')" > "$TEST_PROJECT/scripts/dashboard-viewer.py"
    echo "name: sample-skill" > "$TEST_PROJECT/skills/sample-skill/skill.yaml"

    cat > "$TEST_PROJECT/.venv/bin/python3" <<'EOF'
#!/usr/bin/env bash
if [[ "${1:-}" == "-c" ]]; then
    if [[ "${2:-}" == *"print(count if count > 0 else 7)"* ]]; then
        echo 7
    fi
    exit 0
fi
echo "Python 3.11.0"
EOF
    chmod +x "$TEST_PROJECT/.venv/bin/python3"

    cat > "$TEST_PROJECT/.venv/bin/pip" <<'EOF'
#!/usr/bin/env bash
exit 0
EOF
    chmod +x "$TEST_PROJECT/.venv/bin/pip"

    cat > "$TEST_BIN/tmux" <<'EOF'
#!/usr/bin/env bash
case "${1:-}" in
    -V) echo "tmux 3.4" ;;
    list-sessions) exit 1 ;;
    source-file) exit 0 ;;
    *) exit 0 ;;
esac
EOF
    chmod +x "$TEST_BIN/tmux"

    cat > "$TEST_BIN/node" <<'EOF'
#!/usr/bin/env bash
echo "v20.11.0"
EOF
    chmod +x "$TEST_BIN/node"

    cat > "$TEST_BIN/npm" <<'EOF'
#!/usr/bin/env bash
if [[ "${1:-}" == "-v" ]]; then
    echo "10.8.1"
    exit 0
fi

if [[ "${1:-}" == "install" && "${2:-}" == "-g" && "${3:-}" == "opencode-ai" ]]; then
    cat > "${TEST_STUB_BIN}/opencode" <<'INNER'
#!/usr/bin/env bash
if [[ "${1:-}" == "--version" ]]; then
    echo "OpenCode 0.1.0"
    exit 0
fi
echo "OpenCode stub"
INNER
    chmod +x "${TEST_STUB_BIN}/opencode"
    exit 0
fi

exit 0
EOF
    chmod +x "$TEST_BIN/npm"

    cat > "$TEST_BIN/python3" <<'EOF'
#!/usr/bin/env bash
if [[ "${1:-}" == "--version" ]]; then
    echo "Python 3.11.0"
    exit 0
fi
exit 0
EOF
    chmod +x "$TEST_BIN/python3"

    cat > "$TEST_BIN/claude" <<'EOF'
#!/usr/bin/env bash
if [[ "${1:-}" == "--version" ]]; then
    echo "claude 1.0.0"
    exit 0
fi
if [[ "${1:-}" == "mcp" && "${2:-}" == "list" ]]; then
    exit 0
fi
if [[ "${1:-}" == "mcp" && "${2:-}" == "add" ]]; then
    exit 0
fi
exit 0
EOF
    chmod +x "$TEST_BIN/claude"

    cat > "$TEST_BIN/flock" <<'EOF'
#!/usr/bin/env bash
exit 0
EOF
    chmod +x "$TEST_BIN/flock"

    cat > "$TEST_BIN/inotifywait" <<'EOF'
#!/usr/bin/env bash
exit 0
EOF
    chmod +x "$TEST_BIN/inotifywait"
}

teardown() {
    rm -rf "$TEST_TMP"
}

@test "first_setup: missing opencode is skipped in non-interactive mode and template includes opencode example" {
    run env HOME="$TEST_HOME" PATH="$TEST_BIN:/usr/bin:/bin" TEST_STUB_BIN="$TEST_BIN" \
        INSTALL_OPENCODE=false bash "$TEST_PROJECT/first_setup.sh"

    [ "$status" -eq 0 ]
    [[ "$output" == *"OpenCode CLI: スキップ (任意)"* ]]
    [[ "$output" == *"STEP B: OpenCode を使う場合の provider 設定（任意）"* ]]
    grep -F "type: opencode" "$TEST_PROJECT/config/settings.yaml"
}

@test "first_setup: INSTALL_OPENCODE=true installs opencode-ai and reports success" {
    run env HOME="$TEST_HOME" PATH="$TEST_BIN:/usr/bin:/bin" TEST_STUB_BIN="$TEST_BIN" \
        INSTALL_OPENCODE=true bash "$TEST_PROJECT/first_setup.sh"

    [ "$status" -eq 0 ]
    [[ "$output" == *"OpenCode CLI: インストール完了"* ]]
    [ -x "$TEST_BIN/opencode" ]
}
