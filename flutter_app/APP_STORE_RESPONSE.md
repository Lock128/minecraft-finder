# App Store Connect Response Template

## Response to Guideline 2.1 - Information Needed

### Third-Party Analytics
**Answer**: No, our app does not include any third-party analytics services. The app operates entirely offline and does not collect, transmit, or analyze any user data.

### Third-Party Advertising  
**Answer**: No, our app does not include any third-party advertising. There are no ads, ad networks, or advertising-related code in the application.

### Data Sharing with Third Parties
**Answer**: No data is shared with any third parties because:
- The app does not collect any user data
- All functionality operates entirely offline
- No network connections are made by the app
- The only data stored is user preferences (like search parameters and theme settings) which are saved locally on the device using Flutter's shared_preferences

### User or Device Data Collection
**Answer**: The app does not collect any user or device data beyond what is necessary for basic app functionality:

**Local Storage Only:**
- Search parameters (world seed, coordinates, search preferences) - stored locally to remember user's last search
- App settings (theme preference) - stored locally for user experience
- This data never leaves the user's device and is not transmitted anywhere

**No Data Collection:**
- No personal information
- No device identifiers  
- No location data
- No usage analytics
- No crash reporting
- No network activity

The app is a completely offline utility tool for world seed analysis that operates without any external connections or data collection.

## Additional Information

### App Functionality
Our app is a utility tool that helps users analyze world generation patterns using mathematical algorithms. All calculations are performed locally on the device without requiring internet connectivity or external services.

### Privacy Commitment
We are committed to user privacy and have designed the app to operate completely offline with minimal local data storage for user convenience only.