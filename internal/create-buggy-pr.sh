#!/bin/bash

set -e

# Generate timestamp
TIMESTAMP=$(date +%s)
BRANCH_NAME="buggy-branch-$TIMESTAMP"

# Checkout main
git checkout main

# Create new buggy branch
git checkout -b "$BRANCH_NAME"

# Apply the buggy diff
git apply internal/buggy-branch-diff.diff

# Stage all changes
git add .

# Commit the changes
git commit -m "feat: add Fahrenheit temperature conversion"

# Push to remote
git push -u origin "$BRANCH_NAME"

# Create PR non-interactively
gh pr create --title "feat: add Fahrenheit temperature conversion" --body '## Changes
### Temperature Conversion
- Added `convert_celsius_to_fahrenheit` helper function to convert temperatures from Celsius to Fahrenheit
- Updated `/api/weather-activity` endpoint to return temperature in Fahrenheit instead of Celsius
## Motivation
Users in regions using Fahrenheit (e.g., United States) will benefit from having temperatures displayed in their preferred unit. This change makes the weather data more accessible to these users.
## Testing
- [ ] Verify `/api/weather-activity` returns temperature in Fahrenheit
- [ ] Verify activity recommendations still work correctly
- [ ] Test with various temperature ranges' --base main

# Open PR in web browser
gh pr view --web

git checkout main