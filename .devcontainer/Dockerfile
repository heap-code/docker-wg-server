FROM mcr.microsoft.com/devcontainers/base:trixie

# Trixie packages match the CI versions (shellcheck 0.10.0, bats 1.11.1)
# shfmt is installed by a devcontainer feature: the trixie package is too old
RUN apt-get update \
	&& apt-get install -y --no-install-recommends shellcheck bats \
	&& rm -rf /var/lib/apt/lists/*

# Claude Code CLI (native binary, no Node.js needed)
# ~/.claude is pre-created so the mounted volume inherits vscode ownership
USER vscode
RUN mkdir -p /home/vscode/.claude \
	&& curl -fsSL https://claude.ai/install.sh | bash
ENV PATH="/home/vscode/.local/bin:${PATH}"
USER root
