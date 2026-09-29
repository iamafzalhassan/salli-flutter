# Salli

[![CI](https://github.com/iamafzalhassan/salli-flutter/actions/workflows/ci.yml/badge.svg)](https://github.com/iamafzalhassan/salli-flutter/actions/workflows/ci.yml)
![Flutter](https://img.shields.io/badge/Flutter-3.47-02569B?logo=flutter&logoColor=white)
![BLoC](https://img.shields.io/badge/BLoC-Cubit-13B9FD)
![Security](https://img.shields.io/badge/requests-ECDSA_P--256_signed-E7FF5F)
![Platforms](https://img.shields.io/badge/platforms-Android%20%7C%20iOS-3DDC84)

A peer-to-peer payments and wallet app for Sri Lanka, built with Flutter for Android and iOS in the spirit of Google Pay and PhonePe. Salli (Sinhala slang for money) sends money to any mobile number, pays merchants by scanning LANKAQR, settles electricity, water, phone and insurance bills, reloads prepaid numbers and transfers to any local bank, in English, Sinhala or Tamil.

No money is real. Salli has no CBSL licence and no LankaPay membership, so every payment rail (CEFTS, LANKAQR, JustPay, billers and reload providers) is simulated. The app talks to a documented REST API, answered by a mock server inside the app that behaves like the real one: it keeps a double-entry ledger, enforces limits, verifies every request signature and honours idempotency keys. Swapping it for a real backend changes configuration, not features.

## Features

- **Phone-first sign-in**: a Sri Lankan mobile number, a 6-digit SMS code read through the Android SMS User Consent API, and a 6-digit PIN that refuses weak patterns. A forgotten PIN is reset with a fresh code and, when one is on file, the NIC.
- **Send money** to any mobile number, with recent payees and a lookup that confirms the name before paying.
- **Scan & Pay** with LANKAQR from the camera or from a photo, for static and fixed-amount merchant codes and for personal codes.
- **My QR**: a personal LANKAQR code, with an optional amount, shown at full screen brightness and shareable as an image.
- **Bill payments** to 13 billers across electricity, water, telecom, television, insurance and leasing, including CEB, LECO, the Water Board, SLT-Mobitel, Dialog, Ceylinco Life and LB Finance. An inquiry shows the amount due, billers can be saved with a nickname, and a saved biller can have a monthly reminder or an autopay mandate.
- **Mobile reload** for Dialog, Mobitel, Hutch and Airtel, by amount or from data, voice and combo plans, with the network detected from the number and recently reloaded numbers one tap away.
- **Bank transfers** to ten Sri Lankan banks, simulating CEFTS: a name enquiry shows the account holder before any money moves, branches are asked for only where the bank needs them, and payees can be saved.
- **Requests and splits**: ask someone for money, remind them once a day, decline or cancel, or split a bill between up to ten people with shares that always add up.
- **Payment links** (`salli://app/pay?to=…&amount=…&note=…`) shared with a money request, opening straight to amount entry or review.
- **Top-up and withdraw** through a bank account linked with a simulated JustPay mandate and an SMS code, or a debit card that passes the Luhn check. Only the card's brand and last four digits are kept.
- **Virtual Visa card** with number and CVV revealed after approval and hidden again after 30 seconds, freeze and unfreeze, a 30-day spending limit and card transactions.
- **Activity** with search and filters by type, date and amount, a transaction timeline, repeat payment, dispute reporting, and a monthly PDF statement built on the device.
- **Insights**: the month's spending by category in a donut chart, compared with the month before.
- **Rewards**: points on every merchant, bill and reload payment, redeemable for cashback; scratch cards scratched with a finger; merchant cashback offers; and referrals that pay both friends.
- **Identity verification** from the NIC, photos of both sides and a selfie with a simulated liveness prompt, moving the account from the basic tier to the verified tier with higher limits, and a usage bar against each limit.
- **Notification centre** with an unread badge, written in the reader's language.
- **Security centre** with a security activity log, trusted devices and PIN change, and biometric approval turned on from the profile with the PIN.
- **English, Sinhala and Tamil**, switchable at runtime, and **dark, light or system theme**.
- **Offline awareness**: a banner appears when the server cannot be reached and clears by itself once it can.

## Architecture

- **Clean Architecture per feature.** Sixteen features (account, auth, banks, bills, cards, funding, notifications, onboarding, payments, profile, reload, requests, rewards, security, settings, wallet) each have `data` (dio data sources, models, repository implementations), `domain` (entities, repository contracts, one use case per action) and `presentation` (cubits, states, pages, widgets). The domain is pure Dart: no Flutter, no dio, no plugin.
- **Cubits for state.** Every change is an explicit transition on an immutable `Equatable` state. Nullable fields are cleared through `copyWith(failure: () => null)`, and a cubit checks `isClosed` after every `await` before it emits. Cubits never import `BuildContext` or Material.
- **Typed results.** Data sources throw `ApiException`; repositories wrap every call in `guardApi` and return a sealed `Result<T>` of `Ok` or `Err`; cubits switch on it exhaustively. A `Failure` is a stable error code that maps straight to a translated message.
- **One flow for every way to pay.** A sealed `Recipient` (person, merchant, bill, reload, bank, top-up or withdrawal) goes to amount entry, a `PaymentDraft` to review, and a `PaymentReceipt` to the result screen. A new way to pay adds a `Recipient` case, never a second set of pages.
- **Composition root.** `get_it` registers one module per feature by hand. `go_router` holds the four tabs in a `StatefulShellRoute` and redirects for onboarding, sign-in, app lock and runtime threats. Each page's cubit is created by its route, never by the page.
- **Cross-feature signals.** An in-process event bus (`WalletChanged`, `NotificationsChanged`) refreshes the balance and the notification bell after a payment, so features never import each other.
- **No code generation.** Every `fromJson`, `toJson`, `copyWith` and `props` is written by hand.

## How the money works

- **Money is integer cents.** `Money` wraps an `int` count of cents, so Rs. 1,250.50 is `Money(125050)`. No `double` ever touches an amount, and the API carries integer cents too.
- **Splits always add up.** `Money.split` gives the leftover cents one each to the first shares, so Rs. 10.00 across three people is 3.34, 3.33 and 3.33, and a negative total stays exact. Bill splits use the same method in the app and on the server.
- **One formatter at the edge.** `LkrFormat` renders every amount as `Rs. 1,250.00` with a true minus sign, in tabular figures so columns line up. Amounts are typed on a custom keypad backed by `AmountInput`, which caps whole and fraction digits and never parses a float.
- **A double-entry ledger.** Every transaction debits one account and credits another by the same amount, so all entries always sum to zero and a balance is the sum of its account's entries. A fee is posted as its own transaction under the payment's reference.
- **Limits by identity tier**, over rolling windows that count every outgoing payment and fee:

| Tier | Single payment | 24 hours | 30 days |
|---|---|---|---|
| Basic | Rs. 25,000 | Rs. 50,000 | Rs. 200,000 |
| Verified | Rs. 200,000 | Rs. 500,000 | Rs. 2,000,000 |

## How a payment works

1. **The recipient is resolved first.** A scanned LANKAQR is parsed and checksum-verified on the device before any request, and a merchant's name comes from the server's directory rather than from the sticker, so a look-alike code still shows the registered merchant. A bank account goes through a name enquiry that shows the holder before money moves.
2. **The draft carries an idempotency key.** The amount and note become a `PaymentDraft` with a fresh key, and every retry of that payment reuses it.
3. **The risk is assessed before approval.** A new payee, an amount of Rs. 50,000 or more, or a device bound in the last 24 hours triggers a step-up: biometrics are turned off for that payment, and the PIN pad appears only after a 10-second cooling-off warning.
4. **Approval happens at the moment of payment.** A biometric approval is a hardware signature over the action, the idempotency key, the recipient and the amount, so it cannot be reused for a different payment. Otherwise the PIN is hashed on the device. A cancelled or failed prompt falls back to the PIN pad without an error.
5. **The checkout runs in a fixed order.** The single-payment limit, the 24-hour and 30-day limits and the balance plus any fee are all checked before the approval, so a wrong PIN is never spent on a payment that would fail anyway. The ledger entries are then posted, a Salli recipient is notified, and points and scratch cards are earned.
6. **A replay never moves money twice.** A repeated idempotency key returns the original receipt.

## How the mock API works

- **The mock is the contract.** Data sources call real paths such as `POST /v1/transfers` through one `ApiClient`. In mock mode a Dio interceptor answers them from `MockServer` instead of the network. Every endpoint, body and error code is defined by its handler in `lib/core/mock/modules/`.
- **It behaves like a server, not a stub.** Sixteen modules, one per API area, validate input, enforce balances, limits, lockouts and expiry, add 250 to 700 ms of latency, and return one error envelope: `{"error": {"code": "...", "field": "..."}}`.
- **It verifies what the backend will.** Every authenticated request must carry a valid ECDSA P-256 signature from the bound device, verified with PointyCastle, a timestamp within 60 seconds and an unused nonce. Access tokens expire after 15 minutes and refresh tokens rotate on every use.
- **Demo data is deterministic.** The same bill account always has the same bill and the same bank account the same holder, and set endings demo the edge cases: a bill account ending in `0000` has no bill, and a card ending in `0002` is declined.
- **It works without a phone.** SMS codes appear as an in-app banner, and the scanner offers printed demo codes, so the whole app runs on an emulator with no SIM and no camera.
- **State persists** in the encrypted local database, so balances, history and rewards survive a restart.
- **Every module takes an injectable clock**, so expiry, throttling, lockout and autopay rules are tested without waiting.

## Security

- **Device binding.** On first sign-in the app generates an ECDSA P-256 key pair in the Android Keystore (StrongBox where available) or the iOS Secure Enclave, through platform channels written for the app. The private key never leaves the hardware or enters Dart memory, and binding a new device unbinds the old one.
- **Every authenticated request is signed** over the method, path, sorted query, SHA-256 of the body, timestamp, nonce and device id. `RequestCanonicalizer` is the single definition shared by the app and the mock, so the two can never disagree.
- **Biometrics sign with a second hardware key.** It requires user authentication on every use and is invalidated when the enrolled fingerprints or faces change: `BiometricPrompt` with a `CryptoObject` on Android, `biometryCurrentSet` on iOS. A hooked or bypassed prompt produces no signature.
- **The PIN never leaves the device.** It is stretched with PBKDF2-HMAC-SHA256 (100,000 iterations over a per-user salt) in a background isolate, and only the hash is sent. Five wrong attempts across sign-in, unlock and payments lock it for 30 minutes, and the attempt that locks it at unlock revokes every session.
- **Short sessions.** Access tokens last 15 minutes and are refreshed 30 seconds before they expire, concurrent requests share one refresh, and a reused refresh token revokes its whole session family. Tokens live only in secure storage and memory.
- **App lock.** The app locks on every cold start and after 60 seconds in the background, and the server verifies each unlock. The app switcher only ever shows a blank screen.
- **Runtime protection.** freeRASP watches for root or jailbreak, hooking frameworks, a debugger, emulators, tampering and untrusted installers. Any threat pauses money actions and explains why, and hooking or tampering also ends the session. A release build without its signing certificate hash and team id stays paused.
- **Screen and clipboard.** Release builds set `FLAG_SECURE` on Android, iOS covers the app while the screen is recorded or mirrored, and a copied account number is cleared from the clipboard after 60 seconds.
- **Transport.** Cleartext traffic is disabled. Certificate pinning on the SHA-256 of the server's public key (SPKI), with the certificate's DER parsed by hand, is built into the client and armed from build-time pins for any real host.
- **Data at rest.** Local data lives in AES-256 encrypted Hive boxes whose key is kept only in Keystore-backed and Keychain secure storage, restricted to this device, and Android backup and device transfer are disabled.
- **No enumeration.** Errors never reveal whether a phone number or NIC is registered.

## Built for Sri Lanka

- **Phone numbers** are accepted as `077…`, `77…`, `9477…` or `+9477…`, stored in E.164 and shown as `077 123 4567`, with Dialog, Mobitel, Hutch or Airtel read from the prefix.
- **NIC** in the old format (9 digits and `V` or `X`) and the new one (12 digits), with the date of birth and gender decoded from the day of the year (500 is added for women) and leap years checked. Identity verification rejects a date of birth or gender that does not match the NIC.
- **LANKAQR** follows EMVCo Merchant-Presented QR with a CRC-16/CCITT-FALSE checksum. `LankaQr` is one encoder and parser shared by the app and the mock: it reads any account template from tag 26 to 51, accepts only LKR and Sri Lanka, and rejects a code changed after it was printed.
- **Banks** carry their four-digit CBSL codes and their own account formats. Banks, billers and reload plans all come from the API, so the lists can change without a release.

## Tech stack

| Area | Choice |
|---|---|
| Language | Dart 3.13 |
| UI | Flutter 3.47, Material 3, SF Pro Display |
| State | flutter_bloc (Cubit), equatable |
| Navigation | go_router with a stateful shell and redirect guards |
| Networking | dio with auth, signing, reachability and mock interceptors |
| Dependency injection | get_it |
| Storage | hive_ce (AES encrypted), flutter_secure_storage, shared_preferences |
| Cryptography | crypto (SHA-256, PBKDF2), pointycastle (ECDSA verification in the mock), Android Keystore and iOS Secure Enclave |
| Runtime protection | freerasp |
| Native code | Kotlin and Swift plugins for device keys, biometric keys, screen protection and SMS consent |
| QR | mobile_scanner, qr_flutter, screen_brightness, image_picker |
| Documents | pdf, share_plus |
| Localisation | easy_localization (English, Sinhala, Tamil), intl |

## Design system

Dark, minimal and premium, with one loud accent: near-black surfaces, a neon lime (`#E7FF5F`) primary action, rounded tiles, and a floating pill navigation bar whose raised centre button opens the scanner and gently breathes. Light mode is complete, not an afterthought. Colours, spacing, radii, text styles and motion are tokens in `core/theme`. SF Pro Display carries the interface, and every amount uses tabular figures. Motion helpers stagger content in, count balances up, pulse skeletons while loading and shake on an error, and the entrances, counters and skeletons stand still when the system asks for reduced motion. Shared components (`AppButton`, `AppKeypad`, `AppSheet`, `AppListTile`, `ActionTile`, `SalliNavBar`, `PinEntrySheet`, `ConfirmSheet`, `AmountSheet`, `OfflineBanner`, `PrivacyShield`, and more) live in `core/widgets`. Screens never use a raw colour or a bare measurement.

## Code conventions

- A strict member ordering convention for every class: fields sorted by type tier, then type, then name; methods ordered by call order.
- No comments in source. Names, types and ordering carry the meaning.
- Every user-facing string lives in the English, Sinhala and Tamil translation files, 664 strings each, and all three change together.
- `dart format` at a 240-column page width, with the analyzer's strict casts, strict inference and strict raw types turned on.

## Project structure

```
lib/
    main.dart, app.dart
    core/config/        AppConfig, Environment (mock or staging)
    core/di/            GetIt container, one module per feature
    core/errors/        Result, Failure, failure codes
    core/events/        Cross-feature event bus
    core/localization/  Languages, locale keys, failure messages
    core/mock/          MockServer, ledger, checkout, limits, risk, rewards, authenticator, signature verifier
    core/mock/modules/  One mock module per API area
    core/network/       ApiClient, token refresh, certificate pinning, network status, interceptors
    core/router/        Routes, redirect guards, tab shell
    core/security/      Session, app lock, device and biometric keys, request signing, PIN hashing, approvals, runtime guard
    core/storage/       Secure storage, encrypted Hive, preferences
    core/theme/         Colours, spacing, radius, text styles, motion, theme
    core/utils/         Money, LkrFormat, AmountInput, PhoneNumber, Nic, LankaQr, PaymentLink, CardNumber
    core/widgets/       Shared design-system components
    features/           account, auth, banks, bills, cards, funding, notifications, onboarding, payments, profile, reload, requests, rewards, security, settings, wallet
android/app/src/main/kotlin/com/example/salli/
                        MainActivity, DeviceKeyPlugin, BiometricKeyPlugin, SmsConsentPlugin
ios/Runner/             AppDelegate, DeviceKeyPlugin, BiometricKeyPlugin, ScreenProtectionPlugin
assets/fonts/           SF Pro Display Regular, Medium and Bold
assets/translations/    en, si and ta
```

## Building

**Requirements:** Flutter 3.47 (Dart 3.13), the Android SDK, and Xcode on macOS for iOS.

- **Run:** `flutter pub get`, then `flutter run`. The app starts on the in-app mock API, so it needs no backend and no keys. Sign in with any Sri Lankan mobile number; the code arrives as an in-app SMS banner.
- **Release:** runtime protection needs the base64 SHA-256 of the signing certificate and the Apple team id, or money actions stay paused: `flutter build apk --release --dart-define=SALLI_CERT_HASH=<hash> --dart-define=SALLI_TEAM_ID=<team id>`.
- **Security reports:** `--dart-define=SALLI_SECURITY_MAIL=<address>` sets the address freeRASP sends its security reports to. It defaults to `security@salli.lk`.
- **Staging:** `--dart-define=SALLI_ENV=staging --dart-define=SALLI_SPKI_PINS=<pin>,<backup pin>` points the app at the staging API with certificate pinning armed.

## Testing

464 tests live in `test/`, mirroring the `lib/` path of the code they cover, with hand-written fakes and no mocking library:

- **`test/core/utils/`**: `Money` splits that always sum to the total, `LkrFormat` and `AmountInput`, phone number parsing, both NIC formats with birth date, gender and leap years, payment links, and LANKAQR encoding and parsing, from the CRC-16 check value to rejecting tampered, foreign-currency and foreign-scheme codes.
- **`test/core/security/` and `test/core/network/`**: PBKDF2 PIN hashing, weak PIN detection, request canonicalisation, app lock timing, runtime threat handling, SPKI extraction for certificate pinning, and recovery from offline.
- **`test/core/mock/modules/`**: every API area against the real mock server, with requests signed by a real P-256 key: OTP throttling, expiry and lockout, refresh-token rotation and family revocation, balanced ledger entries, idempotent replays, tier limits, step-ups, and autopay that pays a bill once.
- **`test/features/`**: cubits for payment review (biometric fallback, the step-up cooling-off, idempotent retries), amount entry, scanning, identity verification, PIN entry, splits, rewards, activity and insights, plus model parsing and widget tests for key components.

Run them with `flutter test`.

## Roadmap

- A NestJS, PostgreSQL and Redis backend with a double-entry ledger, replacing the in-app mock without changing a feature
- Play Integrity and App Attest tokens at sign-in and device registration
- Push notifications through FCM and APNs
- Real document upload and liveness checks for identity verification
- R8 shrinking, obfuscation and a dedicated release signing config
