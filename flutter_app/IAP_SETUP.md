# In-App Purchase Setup Guide

This app uses a one-time non-consumable purchase to unlock Pro features.

## Product ID

```
mc_finder_pro_unlock
```

This ID must be configured identically in both stores.

---

## Apple App Store (App Store Connect)

1. Go to [App Store Connect](https://appstoreconnect.apple.com)
2. Navigate to your app > **Monetization** > **In-App Purchases**
3. Click **+** to create a new in-app purchase:
   - **Type**: Non-Consumable
   - **Reference Name**: Pro Unlock
   - **Product ID**: `mc_finder_pro_unlock`
   - **Price**: $4.99 (or your preferred tier)
4. Add localized display name and description for each supported language
5. Submit for review alongside your next app update

### StoreKit Testing (Local)

For local testing in Xcode:
1. Open `ios/Runner.xcworkspace` in Xcode
2. Create a new StoreKit Configuration file: File > New > File > StoreKit Configuration
3. Add a non-consumable product with ID `mc_finder_pro_unlock`
4. In the scheme editor, set the StoreKit Configuration to your file
5. Run the app — purchases will use the sandbox

### Sandbox Testing

1. In App Store Connect > Users & Access > Sandbox Testers, create a test account
2. Sign in on your test device with the sandbox account
3. Purchases will go through the sandbox environment

---

## Google Play Store (Play Console)

1. Go to [Google Play Console](https://play.google.com/console)
2. Navigate to your app > **Monetize** > **Products** > **In-app products**
3. Click **Create product**:
   - **Product ID**: `mc_finder_pro_unlock`
   - **Name**: Pro Unlock
   - **Description**: Unlock all Pro features including unlimited search radius, comprehensive netherite search, all structure types, and more results.
   - **Default price**: $4.99
4. Set status to **Active**

### Testing

1. Add your test account to the **License testing** section (Settings > License testing)
2. Add testers to a closed testing track, or use internal testing
3. The tester will not be charged for purchases

---

## Stripe Payment Link (Web Donations)

The app also includes a "Support Development" button that opens a Stripe Payment Link.

To set up:
1. Go to [Stripe Dashboard](https://dashboard.stripe.com) > Payment Links
2. Create a new payment link with your desired amount (e.g., $5 tip)
3. Replace the placeholder URL in `lib/widgets/app_info_dialog.dart`:
   ```dart
   final Uri uri = Uri.parse('https://donate.stripe.com/YOUR_STRIPE_PAYMENT_LINK');
   ```

---

## Architecture

- **Provider**: `lib/providers/pro_status_provider.dart` — manages IAP lifecycle
- **Dialog**: `lib/widgets/pro_upgrade_dialog.dart` — purchase UI
- **Gating**: `lib/providers/search_state.dart` — applies feature limits based on `isPro`
- **Persistence**: Pro status cached in `SharedPreferences` (key: `is_pro_unlocked`)

## Pro Features (gated for free users)

| Feature | Free | Pro |
|---------|------|-----|
| Search radius | Max 50 blocks | Unlimited |
| Results | Max 50 | Up to 500 |
| Netherite comprehensive search | Blocked | Available |
| Structure types per search | 1 at a time | All 16 simultaneously |
| Future premium features | — | Included |
