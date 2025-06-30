# GitHub Actions Screenshot Generation

This repository includes automated screenshot generation for Android app store submissions using GitHub Actions.

## 🚀 Available Workflows

### 1. Automatic Screenshot Generation
**File**: `.github/workflows/generate-screenshots.yml`

**Triggers**:
- Manual dispatch (workflow_dispatch)
- Push to main branch (when Flutter app changes)
- Weekly schedule (Sundays at 2 AM UTC)

**What it does**:
- Sets up Android emulator
- Builds Flutter app
- Generates screenshots for all Android phone sizes
- Optimizes PNG files
- Commits screenshots back to repository
- Creates GitHub release with screenshots

### 2. Manual Screenshot Generation
**File**: `.github/workflows/manual-screenshots.yml`

**Triggers**:
- Manual dispatch only

**Features**:
- Choose device types (phone, tablet, or both)
- Specify custom screen sizes
- Option to commit or just generate artifacts

## 📱 Generated Screenshot Sizes

### Android Phones
- `1080x1920` - Standard 5.5" phone
- `1440x2560` - 6" phone (QHD)
- `1080x2340` - Modern phone (18:9 aspect)

### Android Tablets
- `1200x1920` - 10" tablet
- `2048x2732` - Large tablet

## 🎯 How to Use

### Option 1: Automatic Generation
1. Push changes to your Flutter app
2. Screenshots will be generated automatically
3. Check the `screenshots/` directory after the workflow completes

### Option 2: Manual Generation
1. Go to **Actions** tab in GitHub
2. Select **Manual Screenshot Generation**
3. Click **Run workflow**
4. Choose your options:
   - Device types: `phone`, `tablet`, or `both`
   - Screen sizes: `all` or specific sizes like `1080x1920,1440x2560`
   - Whether to commit screenshots to repository

### Option 3: API Trigger
```bash
# Trigger via GitHub API
curl -X POST \
  -H "Authorization: token YOUR_GITHUB_TOKEN" \
  -H "Accept: application/vnd.github.v3+json" \
  https://api.github.com/repos/YOUR_USERNAME/YOUR_REPO/actions/workflows/generate-screenshots.yml/dispatches \
  -d '{"ref":"main","inputs":{"commit_message":"Update screenshots via API"}}'
```

## 📁 Output Structure

```
screenshots/
├── android/
│   ├── phone/
│   │   ├── android_phone_1080x1920/
│   │   │   ├── 01_main_screen.png
│   │   │   ├── 02_features.png
│   │   │   ├── 03_interaction.png
│   │   │   ├── 04_results.png
│   │   │   └── 05_settings.png
│   │   ├── android_phone_1440x2560/
│   │   └── android_phone_1080x2340/
│   └── tablet/
│       ├── android_tablet_1200x1920/
│       └── android_tablet_2048x2732/
└── screenshot_summary.md
```

## 🛠️ Customization

### Modify Screenshot Content
Edit the integration test in the workflow to customize what gets captured:

```yaml
# In the workflow file, modify the integration test creation section
- name: Create integration test
  run: |
    # Add your custom screenshot logic here
    # Example: Navigate to specific screens, enter test data, etc.
```

### Add New Device Sizes
Add new configurations to the device configs array:

```dart
final configs = [
  {'name': 'custom_device_1200x1800', 'width': 1200.0, 'height': 1800.0},
  // Add more configurations...
];
```

### Change Screenshot Names
Modify the screenshot file names in the integration test:

```dart
await takeScreenshot(binding, '$outputDir/custom_screenshot_name.png');
```

## 🔧 Troubleshooting

### Common Issues

**1. Emulator fails to start**
- The workflow includes retry logic and extended wait times
- Check the Actions logs for specific emulator errors

**2. Flutter build fails**
- Ensure your `pubspec.yaml` is valid
- Check that all dependencies are available

**3. Screenshots are blank/black**
- App might need more time to load
- Increase the `pumpAndSettle` duration in the test

**4. Integration test dependency missing**
- The workflow automatically adds `integration_test` to `dev_dependencies`
- Ensure your Flutter app structure is correct

### Debug Mode
To debug screenshot generation:

1. Check the Actions logs for detailed output
2. Download the artifacts to see what was generated
3. Look at the `screenshot_summary.md` for generation details

### Local Testing
You can test the integration test locally:

```bash
cd flutter_app

# Add integration_test dependency
flutter pub add integration_test --dev

# Run the test locally
flutter drive \
  --driver=test_driver/integration_test.dart \
  --target=integration_test/screenshot_test.dart
```

## 📋 Store Submission

### Google Play Store
- **Requirements**: 2-8 screenshots per device type
- **Formats**: PNG or JPEG
- **Upload**: Use screenshots from `screenshots/android/phone/` and `screenshots/android/tablet/`

### Optimization
The workflow automatically:
- Optimizes PNG files with `pngquant`
- Reduces file sizes while maintaining quality
- Organizes files by device type

## 🔄 Workflow Status

Check workflow status:
- ✅ **Success**: Screenshots generated and committed
- ⚠️ **Warning**: Partial success (some screenshots may be missing)
- ❌ **Failure**: Check logs for errors

## 📊 Monitoring

The workflows provide:
- **Artifacts**: Download generated screenshots
- **Releases**: Tagged releases with screenshot bundles
- **Commit history**: Track screenshot updates
- **Summary reports**: Details about generated screenshots

## 🚨 Security Notes

- Workflows use `GITHUB_TOKEN` for repository access
- No external secrets required for basic functionality
- Screenshots are committed using GitHub Actions bot account
- All generated content is public in your repository

## 💡 Tips

1. **Timing**: Run screenshot generation after major UI changes
2. **Quality**: Review generated screenshots before store submission
3. **Customization**: Modify the integration test to show your app's best features
4. **Automation**: Set up the weekly schedule to keep screenshots current
5. **Storage**: Screenshots are stored in git - consider file sizes for large repositories

## 🔗 Related Files

- `.github/workflows/generate-screenshots.yml` - Main automated workflow
- `.github/workflows/manual-screenshots.yml` - Manual trigger workflow
- `flutter_app/integration_test/screenshot_test.dart` - Generated during workflow
- `flutter_app/test_driver/integration_test.dart` - Test driver
- `screenshots/` - Output directory (created by workflows)