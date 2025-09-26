#!/bin/bash

# MCP Server Manager Launcher
# This script launches the MCP Server Manager app

# Get the directory where this script is located
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# Change to that directory
cd "$DIR"

# Check if node_modules exists, if not install dependencies
if [ ! -d "node_modules" ]; then
    echo "First time setup - installing dependencies..."
    echo "This may take a minute..."
    npm install
    echo ""
fi

# Start the application
echo "Starting MCP Server Manager..."
npm start