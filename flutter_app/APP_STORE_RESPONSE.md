# App Store Connect Response Template

## Response to Guideline 2.1 - Information Needed

### Third-Party Analytics
**Answer**: The app includes no advertising or marketing analytics. Official builds send technical diagnostics (error reports, page views, usage and performance data, device model, operating system version, app version, and a random session identifier) to our processor Dash0 via OpenTelemetry, for diagnostics and reliability. The app has no accounts and does not assign a user ID. Dash0 anonymizes IP addresses and keeps only city-level approximate location. Data is stored in the EU (eu-west-1) for 30 days (metrics 13 months). Session replay and profiling are off. Data is not sold.

### Third-Party Advertising  
**Answer**: No, our app does not include any third-party advertising. There are no ads, ad networks, or advertising-related code in the application.

### Data Sharing with Third Parties
**Answer**: Data is not sold and is not shared with third parties for advertising or any other purpose:
- Search inputs such as world seeds are never transmitted
- The only network traffic is the technical diagnostics sent to our processor Dash0 (see above)
- The only data stored is user preferences (like search parameters and theme settings) which are saved locally on the device using Flutter's shared_preferences

### User or Device Data Collection
**Answer**: Apart from the technical diagnostics listed below, the app does not collect user or device data:

**Local Storage Only:**
- Search parameters (world seed, coordinates, search preferences) - stored locally to remember user's last search
- App settings (theme preference) - stored locally for user experience
- This data never leaves the user's device

**No Data Collection:**
- No account data or user ID
- No advertising identifiers
- No precise location (Dash0 stores only city-level approximate location derived from the IP address)
- No world seeds, coordinates or search inputs

**Diagnostics (official builds):** error reports, page views, performance data, device model, operating system version, app version (on iOS and Android also a user agent string containing app version, OS version and device model identifier) and a random session identifier, sent to Dash0 over HTTPS. Used only for diagnostics and reliability, not for tracking or advertising.

The app is a utility tool for world seed analysis. Calculations run locally; only the diagnostics above leave the device.

## Additional Information

### App Functionality
Our app is a utility tool that helps users analyze world generation patterns using mathematical algorithms. All calculations are performed locally on the device and the app works without an internet connection.

### Privacy Commitment
We are committed to user privacy and have designed the app to keep user data local, apart from the diagnostics described above.