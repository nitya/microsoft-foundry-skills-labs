#!/bin/bash
set -e

echo ">>> Updating Azure Developer CLI (azd) ..."
azd upgrade --no-prompt

echo ">>> Updating pip ..."
pip install --upgrade pip

echo ">>> Post-create setup complete."
