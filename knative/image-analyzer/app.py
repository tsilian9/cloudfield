#!/usr/bin/env python3
"""
CloudField Image Analyzer – Knative Serverless Function
========================================================
Δέχεται MinIO webhook events (S3-compatible) και επιστρέφει
metadata για το αρχείο που ανέβηκε.

Endpoint: POST /
Input:    MinIO S3 event JSON
Output:   JSON με metadata (filename, size, bucket, timestamp, content-type)
"""

import os
import json
import logging
from datetime import datetime
from flask import Flask, request, jsonify

# Προαιρετικά: boto3 για να κατεβάσουμε και να αναλύσουμε το αρχείο
try:
    import boto3
    from botocore.client import Config
    BOTO3_AVAILABLE = True
except ImportError:
    BOTO3_AVAILABLE = False

# Προαιρετικά: Pillow για image metadata
try:
    from PIL import Image
    import io
    PILLOW_AVAILABLE = True
except ImportError:
    PILLOW_AVAILABLE = False

# ── Logging ────────────────────────────────────────────────────
logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s [%(levelname)s] %(message)s"
)
logger = logging.getLogger(__name__)

# ── Flask App ──────────────────────────────────────────────────
app = Flask(__name__)

# ── MinIO Config (από environment variables) ───────────────────
MINIO_ENDPOINT = os.getenv("MINIO_ENDPOINT", "http://minio.default.svc.cluster.local:9000")
MINIO_ACCESS_KEY = os.getenv("MINIO_ACCESS_KEY", "minioadmin")
MINIO_SECRET_KEY = os.getenv("MINIO_SECRET_KEY", "minioadmin")


def get_minio_client():
    """Δημιουργεί boto3 S3 client για MinIO."""
    if not BOTO3_AVAILABLE:
        return None
    return boto3.client(
        "s3",
        endpoint_url=MINIO_ENDPOINT,
        aws_access_key_id=MINIO_ACCESS_KEY,
        aws_secret_access_key=MINIO_SECRET_KEY,
        config=Config(signature_version="s3v4"),
        region_name="us-east-1",
    )


def analyze_image(s3_client, bucket: str, key: str) -> dict:
    """Κατεβάζει και αναλύει εικόνα από MinIO."""
    if not s3_client or not PILLOW_AVAILABLE:
        return {}
    try:
        response = s3_client.get_object(Bucket=bucket, Key=key)
        image_data = response["Body"].read()
        img = Image.open(io.BytesIO(image_data))
        return {
            "image_width": img.width,
            "image_height": img.height,
            "image_format": img.format,
            "image_mode": img.mode,
        }
    except Exception as e:
        logger.warning(f"Could not analyze image: {e}")
        return {}


@app.route("/", methods=["POST"])
def handle_event():
    """
    Κύριο endpoint – δέχεται MinIO S3 event notification.
    """
    try:
        payload = request.get_json(force=True, silent=True) or {}
        logger.info(f"Received event: {json.dumps(payload, indent=2)}")

        results = []

        # MinIO στέλνει events στο format: {"Records": [...]}
        records = payload.get("Records", [])

        if not records:
            # Fallback: αν δεν υπάρχουν Records, επέστρεψε echo
            return jsonify({
                "status": "ok",
                "message": "No records in event",
                "received": payload,
                "timestamp": datetime.utcnow().isoformat() + "Z"
            })

        s3_client = get_minio_client()

        for record in records:
            event_name = record.get("eventName", "unknown")
            s3_info = record.get("s3", {})
            bucket = s3_info.get("bucket", {}).get("name", "unknown")
            obj = s3_info.get("object", {})
            key = obj.get("key", "unknown")
            size = obj.get("size", 0)
            etag = obj.get("eTag", "")
            content_type = obj.get("contentType", "application/octet-stream")
            event_time = record.get("eventTime", datetime.utcnow().isoformat() + "Z")

            logger.info(f"Processing: bucket={bucket}, key={key}, size={size}")

            # Βασικά metadata
            metadata = {
                "event": event_name,
                "bucket": bucket,
                "filename": key,
                "size_bytes": size,
                "size_kb": round(size / 1024, 2) if size else 0,
                "content_type": content_type,
                "etag": etag,
                "event_time": event_time,
                "processed_at": datetime.utcnow().isoformat() + "Z",
                "minio_url": f"{MINIO_ENDPOINT}/{bucket}/{key}",
            }

            # Επιπλέον image metadata αν είναι εικόνα
            if content_type.startswith("image/") or key.lower().endswith(
                (".jpg", ".jpeg", ".png", ".gif", ".bmp", ".webp")
            ):
                image_meta = analyze_image(s3_client, bucket, key)
                metadata.update(image_meta)

            results.append(metadata)
            logger.info(f"Metadata extracted: {json.dumps(metadata, indent=2)}")

        return jsonify({
            "status": "success",
            "processed": len(results),
            "results": results
        }), 200

    except Exception as e:
        logger.error(f"Error processing event: {e}", exc_info=True)
        return jsonify({
            "status": "error",
            "message": str(e)
        }), 500


@app.route("/health", methods=["GET"])
def health():
    """Health check endpoint."""
    return jsonify({
        "status": "healthy",
        "service": "cloudfield-image-analyzer",
        "version": "1.0.0",
        "boto3": BOTO3_AVAILABLE,
        "pillow": PILLOW_AVAILABLE,
    })


@app.route("/", methods=["GET"])
def root():
    """Root endpoint – info."""
    return jsonify({
        "service": "CloudField Image Analyzer",
        "description": "Knative serverless function για ανάλυση αρχείων από MinIO",
        "endpoints": {
            "POST /": "Δέχεται MinIO S3 event και επιστρέφει metadata",
            "GET /health": "Health check"
        }
    })


if __name__ == "__main__":
    port = int(os.getenv("PORT", 8080))
    logger.info(f"Starting CloudField Image Analyzer on port {port}")
    app.run(host="0.0.0.0", port=port, debug=False)
