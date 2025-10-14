#!/bin/bash

# ReactDemo Production Build Script
# Usage: ./build.sh [bun|deno]

RUNTIME=${1:-bun}

echo "🏗️  Building ReactDemo for production with $RUNTIME runtime..."
echo ""

# Set the runtime environment variable
export REACT_RUNTIME=$RUNTIME

case $RUNTIME in
  "bun")
    echo "📦 Building with Bun runtime..."
    mix phx.react.bun.bundle --component-base=assets/component --output=priv/react/bun/server.js
    ;;
  "deno")
    echo "🦕 Building with Deno runtime..."
    mix phx.react.deno.bundle --component-base=assets/component --output=priv/react/deno/server.js
    ;;
  *)
    echo "❌ Invalid runtime. Use 'bun' or 'deno'"
    exit 1
    ;;
esac

echo ""
echo "✅ Build completed!"
echo "🚀 Start production server with: REACT_RUNTIME=$RUNTIME MIX_ENV=prod mix phx.server"