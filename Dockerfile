# ═══════════════════════════════════════════════════════════════
# Custom Node-RED Image for CloudField
# Contains: flows.json + required npm packages baked-in
# Docker Hub: tsilian9/cloudfield-nodered
# ═══════════════════════════════════════════════════════════════
FROM nodered/node-red:latest

# Copy flows into the image
WORKDIR /data
COPY flows.json flows.json

# Install required Node-RED palettes
RUN npm install \
    @meowwolf/node-red-contrib-amqp@2.4.2 \
    node-red-contrib-s3@0.1.2 \
    --no-audit \
    --no-fund

# Expose port
EXPOSE 1880
