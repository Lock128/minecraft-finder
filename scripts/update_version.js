#!/usr/bin/env node

/**
 * Script to automatically update Flutter version based on environment variables
 * This script should be run before flutter build commands in CodeMagic
 */

const fs = require('fs');
const path = require('path');

// Default values
const DEFAULT_VERSION_NAME = '1.0.0';
const DEFAULT_BUILD_NUMBER = '1';

// Get version name and build number from environment variables or use defaults
const versionName = process.env.FLUTTER_BUILD_NAME || DEFAULT_VERSION_NAME;
const buildNumber = process.env.FLUTTER_BUILD_NUMBER || DEFAULT_BUILD_NUMBER;

// Path to pubspec.yaml
const pubspecPath = path.join(__dirname, '..', 'frontend', 'src', 'pubspec.yaml');

try {
  // Check if pubspec.yaml exists
  if (!fs.existsSync(pubspecPath)) {
    console.error(`Error: pubspec.yaml not found at ${pubspecPath}`);
    process.exit(1);
  }

  // Read the current pubspec.yaml
  let pubspecContent = fs.readFileSync(pubspecPath, 'utf8');

  // Update the version line
  const newVersion = `${versionName}+${buildNumber}`;
  const versionRegex = /^version:\s+.+$/m;

  if (versionRegex.test(pubspecContent)) {
    pubspecContent = pubspecContent.replace(versionRegex, `version: ${newVersion}`);
    console.log(`Updating version to: ${newVersion}`);
  } else {
    console.error('Error: Could not find version line in pubspec.yaml');
    process.exit(1);
  }

  // Write the updated content back to the file
  fs.writeFileSync(pubspecPath, pubspecContent, 'utf8');

  console.log(`Version updated successfully in ${pubspecPath}`);

  // Verify the update
  const updatedContent = fs.readFileSync(pubspecPath, 'utf8');
  const versionMatch = updatedContent.match(/^version:\s+(.+)$/m);
  if (versionMatch) {
    console.log(`Current version: ${versionMatch[1]}`);
  }
} catch (error) {
  console.error('Error updating version:', error.message);
  process.exit(1);
}
