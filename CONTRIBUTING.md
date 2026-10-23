# Contributing

Thanks for your interest in contributing!
Bug reports, questions and pull requests are welcome.

## Requirements

- [Docker](https://docs.docker.com/get-docker/)
- `make`

The linters and the unit tests run inside Docker, at pinned versions, so nothing else needs to be installed.

Alternatively, open the repository in the [devcontainer](.devcontainer/devcontainer.json) (VS Code, GitHub Codespaces, ...).
It comes with Docker, `shellcheck`, `shfmt` and `bats`, and formats shell scripts on save.

## Commands

| Command | Description |
| --- | --- |
| `make lint` | Check the shell scripts and tests with `shellcheck` and `shfmt` |
| `make fmt` | Format the shell scripts and tests with `shfmt` |
| `make test-unit` | Build the `test` image and run the unit tests in it |
| `make build` | Build the image (`wg-server:dev`, override with `IMAGE=...`) |

Before opening a pull request, make sure `make lint` and `make test-unit` pass.
The [CI](.github/workflows/ci.yml) runs them, and the integration tests, on every pull request and push to `master`.

### Integration tests

`make test-integration` builds the image and starts a server and a client container,
then checks a real WireGuard connection between them (including disabling/enabling a peer with `sync`).
They take about 30 seconds.

They need `bats` on the host (included in the devcontainer), a kernel with the WireGuard module
and permission to run `NET_ADMIN` containers.

`make test` runs the unit and integration tests, and `make all` runs the linters and all the tests.

## Code style

- Scripts are POSIX `sh` (the image is Alpine-based), checked by `shellcheck`.
- Formatting follows [.editorconfig](.editorconfig) (tabs for `*.sh` and `*.bats`), applied by `shfmt`.
  Run `make fmt` to fix formatting issues.
- Add or update the [bats](https://bats-core.readthedocs.io/) tests in `tests/` when changing behavior,
  and update the [README](README.md) when adding or changing an environment variable.

## Commits

Commit messages follow [Conventional Commits](https://www.conventionalcommits.org/),
e.g. `fix: ...`, `feat: ...`, `docs: ...`.
