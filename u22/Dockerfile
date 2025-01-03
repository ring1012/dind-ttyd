# Start with the base image of Ubuntu 22.04
FROM ubuntu:22.04

# Set environment variables to avoid prompts during installation
ENV DEBIAN_FRONTEND=noninteractive

# Update package list and install required dependencies
RUN apt-get update && apt-get install -y \
    sudo \
    build-essential \
    cmake \
    git \
    libjson-c-dev \
    libwebsockets-dev \
    libssl-dev \
    curl \
    && rm -rf /var/lib/apt/lists/*

# Create a user `aml` with password `aml` and add to sudo group
RUN useradd -m -s /bin/bash aml && \
    echo "aml:aml" | chpasswd && \
    usermod -aG sudo aml

# Clone and build ttyd from source
RUN git clone https://github.com/tsl0922/ttyd.git /tmp/ttyd && \
    cd /tmp/ttyd && \
    mkdir build && \
    cd build && \
    cmake .. && \
    make && \
    make install && \
    cd / && \
    rm -rf /tmp/ttyd

# Expose port 80
EXPOSE 80

# Set ttyd as the entrypoint
ENTRYPOINT ["ttyd", "-p", "80", "--check-origin=false", "/bin/login"]
