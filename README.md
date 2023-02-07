# Relez

Relez is a collection of reusable Github Workflows (`relez-flows`) and a set of automated testing tooling to validate that these workflows work as expected (`relez-testing`). The goal of this repository is twofold: I'm testing out some flows that I want to use in my own projects, and I'm also prototyping methods of testing these flows.

Relez is not currently production-ready, and maybe never will be. It's a work in progress.

## relez-flows

`relez-flows` is what I'm calling my collection of reusable Github Workflows that can be used in your own projects.

## relez-testing

`relez-testing` is a collection name for tooling that can be used to validate that your Github Workflows are functioning correctly. The tests are written using the [Bash Automated Testing System (Bats)](https://github.com/bats-core/bats-core).

Currently, we are building tests to validate that `relez-flows` works as expected using integration tests: we are testing the workflows in a real Github repository. Github may not like this approach, so we may want to switch to [act](act) in the future, and run integration tests in a single repository that we clean up after each test run.

[act]: https://github.com/nektos/act

### Running the tests

To run the tests, execute `./test`.

## Contributions

We welcome contributions to the `relez` repository. Please feel free to open a pull request.

## License

This project is licensed under the [EUPL-1.2-or-later](https://joinup.ec.europa.eu/collection/eupl/eupl-text-eupl-12).
