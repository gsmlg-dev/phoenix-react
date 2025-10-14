#!/bin/bash

# ReactDemo Development Server Launcher
# Usage: ./dev.sh [bun|deno]

RUNTIME=${1:-bun}

echo "🚀 Starting ReactDemo with $RUNTIME runtime..."
echo "📝 Runtime: $RUNTIME"
echo "🌐 Server will be available at: http://localhost:4666"
echo ""

# Set the runtime environment variable
export REACT_RUNTIME=$RUNTIME

# Start the Phoenix server
mix phx.server