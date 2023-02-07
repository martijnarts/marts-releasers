#!/usr/bin/env bats

wait_for_job() {
    local job_name=$1
    local max_wait_time=$2
    local wait_interval=$3
    local repository=$4
    local start_time=$(date +%s)
    local current_time=$start_time

    while [ $((current_time - start_time)) -lt $max_wait_time ]; do
        jobs=$(gh run list -R "martijnarts/$repository")
        if [ "$(echo "${jobs}" | grep "${job_name}")" ]; then
            return 0
        fi
        sleep $wait_interval
        current_time=$(date +%s)
    done
    return 1
}

setup_file() {
    export REPO_NAME="relez-test-repo-$(date +%s)"
    cd $BATS_FILE_TMPDIR
    mkdir "$REPO_NAME"
    cd "$REPO_NAME"
    git init --initial-branch main

    mkdir -p .github/workflows/
    cp -r "$BATS_TEST_DIRNAME/../.github/workflows/" .github/workflows/
    git add .
    git commit -m "Add workflows"

    gh repo create --public "$REPO_NAME" --push --source .
}

teardown_file() {
    gh repo delete "$REPO_NAME" --yes
}

@test "PR creation should trigger specified jobs" {
    cd "$BATS_FILE_TMPDIR/$REPO_NAME"

    touch test-file
    git switch -c test-branch
    git add .
    git commit -m "Add test file"
    git push -u origin test-branch
    sleep 1
    gh pr create --base main --head test-branch --title test --body test

    if ! wait_for_job "Generate Changelog JSON" 15 5 "$REPO_NAME"; then
        return 1
    fi

    return 0
}
