FROM python:3.12-slim

# Install git, bash, and curl (required for Tusk CLI and git operations)
RUN apt-get update && apt-get install -y --no-install-recommends \
    git \
    bash \
    curl \
    && rm -rf /var/lib/apt/lists/*

# Create non-root user
RUN useradd -m -s /bin/bash vscode

# Set bash as default shell
SHELL ["/bin/bash", "-c"]

# Switch to vscode user
USER vscode
WORKDIR /home/vscode

# Set default shell for the user
ENV SHELL=/bin/bash

