# ---- Builder Stage ----
FROM jlesage/baseimage-gui:alpine-3.18-v4.7 AS builder

# Install Python and build deps
RUN add-pkg \
    python3 \
    py3-pip \
    build-base \
    python3-dev \
    musl-dev \
    linux-headers \
    git \
    jpeg-dev \
    zlib-dev \
    freetype-dev \
    tk-dev \
    tcl-dev \
    python3-tkinter

WORKDIR /app
COPY . .

# Create venv, install deps, build binary
RUN python3 -m venv env && \
    . env/bin/activate && \
    pip install --upgrade pip wheel && \
    pip install --no-cache-dir -r requirements.txt pyinstaller && \
    pyinstaller build.spec && \
    # Rename the binary to avoid spaces in filename
    mv "/app/dist/Twitch Drops Miner (by DevilXD)" /app/dist/TwitchDropsMiner

# ---- Runtime Stage ----
FROM jlesage/baseimage-gui:alpine-3.18-v4.7

# Environment variables
ENV LANG=en_US.UTF-8 \
    DARK_MODE=1 \
    KEEP_APP_RUNNING=1 \
    APP_ICON_URL=https://raw.githubusercontent.com/Davixk/TwitchDropsMiner/stable/appimage/pickaxe.png

# Install runtime dependencies only
RUN add-pkg \
    jpeg \
    zlib \
    freetype \
    tk \
    tcl \
    font-noto \
    font-noto-emoji \
    fontconfig \
    libx11 \
    libxrender

# Create TwitchDropsMiner directory
RUN mkdir -p /TwitchDropsMiner

# Copy the binary from builder stage
COPY --from=builder /app/dist/TwitchDropsMiner /TwitchDropsMiner/TwitchDropsMiner

# Set up config/cache links
RUN mkdir -p /config /cache && \
    ln -s /config /TwitchDropsMiner/config && \
    ln -s /cache /TwitchDropsMiner/cache

RUN chmod -R 777 /TwitchDropsMiner
RUN chown -R 1000:1000 /TwitchDropsMiner /config /cache

# Copy the start script
COPY startapp.sh /startapp.sh
RUN chmod +x /startapp.sh

# Install icon
RUN install_app_icon.sh "$APP_ICON_URL"

# Set app info
RUN set-cont-env APP_NAME "Twitch Drops Miner" && \
    set-cont-env APP_VERSION "1.0"

# Expose ports
EXPOSE 5800 5900