#!/usr/bin/env bash

set -euo pipefail

usage() {
  cat <<'EOF'
Usage: ./deploy.sh [--build] [--pull-base]

  --build   Rebuild the production image before recreating the service.
  --pull-base
            Explicitly allow BuildKit to fetch the pinned Node base image.
            The default build reuses the local base-image cache.
  --help    Show this help.
EOF
}

BUILD=0
PULL_BASE=0
for arg in "$@"; do
  case "$arg" in
    --build)
      BUILD=1
      ;;
    --pull-base)
      PULL_BASE=1
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
  build_args=(--builder default --pull=false)
  if [[ "$PULL_BASE" == 1 ]]; then
    build_args=(--builder default --pull)
    echo "Base-image pull enabled explicitly; the Dockerfile still pins an exact Node digest."
  else
    echo "Base-image pull disabled; reusing the locally cached pinned Node image."
  fi

  if ! docker compose build "${build_args[@]}"; then
    echo ""
    echo "Build failed while using the pinned local Node base-image cache."
    echo "If the cache is missing, run deploy.sh --build --pull-base once on a"
    echo "network that can reach public.ecr.aws, then keep using deploy.sh --build."
    exit 1
  fi
else
  echo "Skipping image build; use ./deploy.sh --build to rebuild."
fi

echo "Starting services in detached mode..."
docker compose up -d
docker compose ps

echo "✅ All done! Services are now running."
