#!/usr/bin/env bats

setup_file() {
    export REPO_NAME="relez-test-repo-$(date +%s)"
    cd $BATS_FILE_TMPDIR
    mkdir "$REPO_NAME"
    cd "$REPO_NAME"
    git init --initial-branch main

    mkdir -p .github/workflows/
    mkdir -p .changelog/draft/
    touch .changelog/draft/.gitkeep
    cp -r "$BATS_TEST_DIRNAME/../../relez-flows/" .github/workflows/
    git add .
    git commit -m "Add workflows"

    gh repo create --public "$REPO_NAME" --push --source .
}

teardown_file() {
    echo # gh repo delete "$REPO_NAME" --yes
}

@test "Pushing to main branch should eventually create release PR" {
    cd "$BATS_FILE_TMPDIR/$REPO_NAME"

    git tag -a v0.0.0 -m "v0.0.0

user-facing-version: v0.0.0"

    jq -n '{
        "prNumber": 1,
        "changeTitle": "Test",
        "changeSummary": "Test",
        "changeTags": ["require-runtime-build", "user-facing-minor"],
    }' >.changelog/draft/pr1.json
    git add .
    git commit -m "Add PR1"
    git push && git push --tags

    if ! $BATS_TEST_DIRNAME/../utils/wait_for_job "Update release branch" 15 5 "$REPO_NAME"; then
        return 1
    fi
}
