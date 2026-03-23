FROM python:3.12-slim

# Install base tooling plus sudo for post-create package installs
RUN apt-get update && apt-get install -y --no-install-recommends \
    git \
    bash \
    curl \
    sudo \
    && rm -rf /var/lib/apt/lists/*

# Create non-root user
RUN useradd -m -s /bin/bash vscode

# Allow the devcontainer user to install extra packages during setup
RUN echo "vscode ALL=(root) NOPASSWD:ALL" > /etc/sudoers.d/vscode \
    && chmod 0440 /etc/sudoers.d/vscode

# Set bash as default shell
SHELL ["/bin/bash", "-c"]

# Switch to vscode user
USER vscode
WORKDIR /home/vscode

# Set default shell for the user
ENV SHELL=/bin/bash

