#!/bin/bash
# ═══════════════════════════════════════════════════════════════
# CloudField SLA Measurement Script – Φάση G
# Μετρά: Knative cold/warm start + end-to-end latency
# Χρήση: bash sla-measure.sh | tee sla-results.txt
# ═══════════════════════════════════════════════════════════════

KOURIER_PORT=8081
KNATIVE_HOST="image-analyzer.default.172.31.76.79.nip.io"
PAYLOAD='{"Records": [{"eventName": "s3:ObjectCreated:Put", "s3": {"bucket": {"name": "farm-data"}, "object": {"key": "photo.jpg", "size": 2048, "contentType": "image/jpeg"}}}]}'

echo "════════════════════════════════════════════════════════"
echo "  CloudField SLA Measurements – $(date '+%Y-%m-%d %H:%M:%S')"
echo "════════════════════════════════════════════════════════"
echo ""

# ── Βεβαιώσου ότι το Kourier port-forward τρέχει ─────────────
if ! curl -s http://localhost:${KOURIER_PORT} > /dev/null 2>&1; then
  echo "⚠️  Ξεκινώ Kourier port-forward..."
  kubectl port-forward -n knative-serving svc/kourier ${KOURIER_PORT}:80 &
  PF_PID=$!
  sleep 3
fi

# ── G.1: COLD START LATENCY ───────────────────────────────────
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "G.1 – Knative COLD START Latency"
echo "      (scale-to-zero → πρώτο request)"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# Περίμενε να πάει σε scale-to-zero (αν δεν είναι ήδη)
echo "⏳ Ελέγχω αν το image-analyzer pod τρέχει..."
PODS=$(kubectl get pods -l serving.knative.dev/service=image-analyzer --no-headers 2>/dev/null | grep -c Running || echo 0)

if [ "$PODS" -gt "0" ]; then
  echo "   Pod τρέχει. Περιμένω scale-to-zero (65 δευτ.)..."
  sleep 65
  echo "   Scale-to-zero ολοκληρώθηκε."
else
  echo "   Pod δεν τρέχει (scale-to-zero ήδη)."
fi

echo ""
echo "🚀 Στέλνω cold start request..."
COLD_START=$(curl -s -o /dev/null \
  -w "%{time_total}" \
  -X POST http://localhost:${KOURIER_PORT} \
  -H "Host: ${KNATIVE_HOST}" \
  -H "Content-Type: application/json" \
  -d "${PAYLOAD}")

echo "   Cold Start Latency: ${COLD_START}s"
echo ""

# ── G.2: WARM START LATENCY ───────────────────────────────────
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "G.2 – Knative WARM START Latency"
echo "      (pod ήδη τρέχει – 5 μετρήσεις)"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

WARM_TOTAL=0
WARM_MIN=999
WARM_MAX=0

for i in 1 2 3 4 5; do
  T=$(curl -s -o /dev/null \
    -w "%{time_total}" \
    -X POST http://localhost:${KOURIER_PORT} \
    -H "Host: ${KNATIVE_HOST}" \
    -H "Content-Type: application/json" \
    -d "${PAYLOAD}")
  echo "   Warm Start #${i}: ${T}s"
  WARM_TOTAL=$(echo "$WARM_TOTAL + $T" | bc)
  if (( $(echo "$T < $WARM_MIN" | bc -l) )); then WARM_MIN=$T; fi
  if (( $(echo "$T > $WARM_MAX" | bc -l) )); then WARM_MAX=$T; fi
done

WARM_AVG=$(echo "scale=3; $WARM_TOTAL / 5" | bc)
echo ""
echo "   Warm Start Min:  ${WARM_MIN}s"
echo "   Warm Start Max:  ${WARM_MAX}s"
echo "   Warm Start Avg:  ${WARM_AVG}s"
echo ""

# ── G.3: END-TO-END LATENCY ───────────────────────────────────
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "G.3 – End-to-End Latency"
echo "      (RabbitMQ Management API response time)"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# RabbitMQ Management API latency
RMQ_LATENCY=$(curl -s -o /dev/null \
  -w "%{time_total}" \
  -u guest:guest \
  http://rabbitmq.172.31.76.79.nip.io/api/overview 2>/dev/null || \
  kubectl exec deployment/rabbitmq -- \
  curl -s -o /dev/null -w "%{time_total}" -u guest:guest http://localhost:15672/api/overview 2>/dev/null)

echo "   RabbitMQ API Latency: ${RMQ_LATENCY}s"

# MinIO API latency
MINIO_LATENCY=$(curl -s -o /dev/null \
  -w "%{time_total}" \
  http://minio.172.31.76.79.nip.io/minio/health/live 2>/dev/null)
echo "   MinIO Health Latency: ${MINIO_LATENCY}s"

# Node-RED API latency
NODERED_LATENCY=$(curl -s -o /dev/null \
  -w "%{time_total}" \
  http://nodered.172.31.76.79.nip.io/ 2>/dev/null)
echo "   Node-RED Latency:     ${NODERED_LATENCY}s"

echo ""

# ── SUMMARY ───────────────────────────────────────────────────
echo "════════════════════════════════════════════════════════"
echo "  ΑΠΟΤΕΛΕΣΜΑΤΑ SLA"
echo "════════════════════════════════════════════════════════"
echo ""
echo "  Knative Cold Start:  ${COLD_START}s"
echo "  Knative Warm Avg:    ${WARM_AVG}s"
echo "  Knative Warm Min:    ${WARM_MIN}s"
echo "  Knative Warm Max:    ${WARM_MAX}s"
echo "  RabbitMQ API:        ${RMQ_LATENCY}s"
echo "  MinIO Health:        ${MINIO_LATENCY}s"
echo "  Node-RED:            ${NODERED_LATENCY}s"
echo ""
echo "════════════════════════════════════════════════════════"
echo "  Αποθήκευσε τα αποτελέσματα: bash sla-measure.sh | tee sla-results.txt"
echo "════════════════════════════════════════════════════════"
