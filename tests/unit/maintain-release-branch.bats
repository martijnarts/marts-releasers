#!/usr/bin/env bats

setup() {
    cd $BATS_TEST_TMPDIR
    git init -b main
    echo "foo" >foo
    git add foo
    git commit --no-verify -m "foo"

    mkdir -p .changelog/draft/

    export GITHUB_ENV=$BATS_TEST_TMPDIR/.github_env
    export BUILD_RUNTIME_LABEL="build-runtime"
    export APP_STORE_REVIEW_LABEL="app-store-review"
    export USER_FACING_MAJOR_LABEL="user-facing-major"
    export USER_FACING_MINOR_LABEL="user-facing-minor"
}

@test "find highest version from git tags" {
    BASH=$(
        yq '.jobs.maintain_release_branch.steps[] | select(.id == "highest_version") | .run' \
            $BATS_TEST_DIRNAME/../../relez-flows/maintain-release-branch.yml
    )

    git tag -a v0.1.0 -m "v0.1.0

user-facing-version: v1.0.0"
    git tag -a v0.2.0 -m "v0.2.0

user-facing-version: v1.1.0"

    run bash -ec "$BASH"
    [ "$status" -eq 0 ]

    grep -q "HIGHEST_PUBLISHED_VERSION=v0.2.0" $GITHUB_ENV
    grep -q "HIGHEST_PUBLISHED_USER_FACING_VERSION=v1.1.0" $GITHUB_ENV
}

@test "collect all draft PRs and included changes in existing file" {
    BASH=$(
        yq '.jobs.maintain_release_branch.steps[] | select(.id == "collect_draft_prs") | .run' \
            $BATS_TEST_DIRNAME/../../relez-flows/maintain-release-branch.yml
    )

    git tag -a v0.1.0 -m "v0.1.0

user-facing-version: v1.0.0"

    jq -n '{
        "prNumber": 3,
        "changeTitle": "three",
        "changeSummary": "bar",
        "changeTags": ["two"],
    }' >$BATS_TEST_TMPDIR/.changelog/draft/pr3.json
    jq -n '{
        "prNumber": 4,
        "changeTitle": "four",
        "changeSummary": "bar",
        "changeTags": ["four"],
    }' >$BATS_TEST_TMPDIR/.changelog/draft/pr4.json
    git add .changelog
    git commit --no-verify -m "Update draft PRs"

    jq -n '{
        "version": "v0.1.0",
        "userFacingVersion": "v1.0.0",
        "includedChanges": [
            {
                "prNumber": 1,
                "changeTitle": "foo",
                "changeSummary": "bar",
                "changeTags": ["one", "two"]
            },
            {
                "prNumber": 2,
                "changeTitle": "qux",
                "changeSummary": "baz",
                "changeTags": ["two", "three"]
            }
        ]
    }' >$BATS_TEST_TMPDIR/.changelog/v0.1.0.json
    git add .changelog
    git commit --no-verify -m "Update release branch"

    run bash -ec "$BASH"
    [ "$status" -eq 0 ]

    cat .changelog/v0.1.0.json
    jq -e '.includedChanges | length == 4' .changelog/v0.1.0.json
}

@test "collect all draft PRs without existing file" {
    BASH=$(
        yq '.jobs.maintain_release_branch.steps[] | select(.id == "collect_draft_prs") | .run' \
            $BATS_TEST_DIRNAME/../../relez-flows/maintain-release-branch.yml
    )

    git tag -a v0.1.0 -m "v0.1.0

user-facing-version: v1.0.0"

    jq -n '{
        "prNumber": 3,
        "changeTitle": "three",
        "changeSummary": "bar",
        "changeTags": ["two"],
    }' >$BATS_TEST_TMPDIR/.changelog/draft/pr3.json
    jq -n '{
        "prNumber": 4,
        "changeTitle": "four",
        "changeSummary": "bar",
        "changeTags": ["four"],
    }' >$BATS_TEST_TMPDIR/.changelog/draft/pr4.json
    git add .changelog
    git commit --no-verify -m "Update draft PRs"

    run bash -ec "$BASH"
    [ "$status" -eq 0 ]

    cat .changelog/vDRAFT.json
    jq -e '.includedChanges | length == 2' .changelog/vDRAFT.json
}

@test "calculate version increments" {
    BASH=$(
        yq '.jobs.maintain_release_branch.steps[] | select(.id == "calculate_version_increments") | .run' \
            $BATS_TEST_DIRNAME/../../relez-flows/maintain-release-branch.yml
    )

    export CHANGELOG_FILE=.changelog/v0.1.0.json
    jq -n '{
        "version": "v0.1.0",
        "userFacingVersion": "v1.0.0",
        "includedChanges": [
            {
                "prNumber": 1,
                "changeTitle": "foo",
                "changeSummary": "bar",
                "changeTags": ["build-runtime"]
            },
            {
                "prNumber": 2,
                "changeTitle": "qux",
                "changeSummary": "baz",
                "changeTags": ["user-facing-minor"]
            }
        ]
    }' >.changelog/v0.1.0.json

    bash -ec "$BASH"

    grep -q 'VERSION_INCREMENT="major"' $GITHUB_ENV
    grep -q 'USER_FACING_VERSION_INCREMENT="minor"' $GITHUB_ENV
}

@test "increment published version and rename changelog file" {
    BASH=$(
        yq '.jobs.maintain_release_branch.steps[] | select(.id == "increment_version") | .run' \
            $BATS_TEST_DIRNAME/../../relez-flows/maintain-release-branch.yml
    )

    export CHANGELOG_FILE=.changelog/v0.1.0.json
    jq -n '{
        "version": "v0.1.0",
        "userFacingVersion": "v1.0.0",
        "includedChanges": [
            {
                "prNumber": 1,
                "changeTitle": "foo",
                "changeSummary": "bar",
                "changeTags": ["build-runtime"]
            },
            {
                "prNumber": 2,
                "changeTitle": "qux",
                "changeSummary": "baz",
                "changeTags": ["user-facing-minor"]
            }
        ]
    }' >.changelog/v0.1.0.json

    export HIGHEST_PUBLISHED_VERSION=v0.1.0
    export HIGHEST_PUBLISHED_USER_FACING_VERSION=v1.0.0

    export VERSION_INCREMENT="major"
    export USER_FACING_VERSION_INCREMENT="minor"

    run bash -ec "$BASH"
    [ "$status" -eq 0 ]

    grep -q 'VERSION=v1.0.0' $GITHUB_ENV
    grep -q 'USER_FACING_VERSION=v1.1.0' $GITHUB_ENV

    [ -f .changelog/v1.0.0.json ]
    [ ! -f .changelog/v0.1.0.json ]

    jq -e '.version == "v1.0.0"' .changelog/v1.0.0.json
    jq -e '.userFacingVersion == "v1.1.0"' .changelog/v1.0.0.json
}
