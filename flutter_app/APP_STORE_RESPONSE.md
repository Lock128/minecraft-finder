# App Store Connect Response Template

## Response to Guideline 2.1 - Information Needed

### Third-Party Analytics
**Answer**: The app includes no advertising or marketing analytics. The app does not collect or transmit personal data. Official builds can send anonymous technical diagnostics (crash reports, screen navigation, performance timings, basic device information, a random session identifier) to Dash0 via OpenTelemetry; the receiving server also sees the IP address of the request.

### Third-Party Advertising  
**Answer**: No, our app does not include any third-party advertising. There are no ads, ad networks, or advertising-related code in the application.

### Data Sharing with Third Parties
**Answer**: No data is shared with any third parties because:
- The app does not collect personal data
- Search inputs such as world seeds are never transmitted
- The only network traffic is optional anonymous diagnostics sent to our processor Dash0
- The only data stored is user preferences (like search parameters and theme settings) which are saved locally on the device using Flutter's shared_preferences

### User or Device Data Collection
**Answer**: The app does not collect any user or device data beyond what is necessary for basic app functionality:

**Local Storage Only:**
- Search parameters (world seed, coordinates, search preferences) - stored locally to remember user's last search
- App settings (theme preference) - stored locally for user experience
- This data never leaves the user's device and is not transmitted anywhere

**No Data Collection:**
- No personal information
- No advertising or hardware device identifiers
- No location data
- No account data

**Optional diagnostics (official builds):** anonymous crash reports, screen navigation, performance timings, basic device information and a random session identifier, sent to Dash0 over HTTPS. Not linked to the user, not used for tracking.

The app is a utility tool for world seed analysis. Calculations run locally; only the optional diagnostics above leave the device.

## Additional Information

### App Functionality
Our app is a utility tool that helps users analyze world generation patterns using mathematical algorithms. All calculations are performed locally on the device without requiring internet connectivity.

### Privacy Commitment
We are committed to user privacy and have designed the app to keep user data local, apart from the optional anonymous diagnostics described above.