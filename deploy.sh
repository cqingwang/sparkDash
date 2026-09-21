#!/usr/bin/env bash

set -euo pipefail

usage() {
  cat <<'EOF'
Usage: ./deploy.sh [--build]

  --build   Rebuild the production image before recreating the service.
  --help    Show this help.
EOF
}

BUILD=0
for arg in "$@"; do
  case "$arg" in
    --build)
      BUILD=1
      ;;
    --help|-h)
      usage
      exit 0
      ;;
    *)
      echo "Unknown argument: $arg" >&2
      usage >&2
      exit 2
      ;;
  esac
done

echo "Stopping and removing containers..."
docker compose down

if [[ "$BUILD" == 1 ]]; then
  echo "Building images..."
  if ! docker compose build; then
    echo ""
    echo "Build failed. If you saw auth.docker.io / 'network is unreachable' on an IPv6 address,"
    echo "Docker Hub is being reached over broken IPv6. This repo pulls Node from"
    echo "public.ecr.aws (IPv4-first). Pull latest deploy.sh + Dockerfiles and retry."
    echo "Host workaround: add this line to /etc/gai.conf then retry:"
    echo "  precedence ::ffff:0:0/96  100"
    exit 1
  fi
else
  echo "Skipping image build; use ./deploy.sh --build to rebuild."
fi

echo "Starting services in detached mode..."
docker compose up -d
docker compose ps

echo "✅ All done! Services are now running."
