# Vitra

Vitra is a calorie and nutrition tracking app for **iOS and Android**, focused on
the Turkish market with broad international coverage.

It is being built by a founder with **no prior software-development background**,
using Claude (Anthropic) as the full product team — architecture, code, UI/UX,
QA, and the data pipeline.

## Features

- **Offline-first food database** — ~300.000 foods and dishes (Turkish + international)
  compiled into the app, so search works without a connection
- **Barcode scanning** for packaged products
- **Daily calorie & macro tracking** — protein, carbohydrate, fat, fiber, sugar, sodium
- **Personalized targets** based on the user's profile
- **Meal & recipe logging**
- **Cloud sync** with offline fallback

## Tech stack

- **Flutter (Dart)** — a single codebase targeting iOS, Android, Web, and desktop
- **Firebase** — Authentication, Firestore, Crashlytics, App Check
- **Local food database** generated and bundled for fully offline use

## Repository layout

```
vitra/                 Flutter application
  lib/                 Dart source
    core/data/         Bundled offline food database (~18.5k items)
    core/services/     Search, barcode, cloud, and external-API services
    features/          App screens and feature modules
  android/ ios/ web/   Platform targets
```

## A note on configuration

For security, environment files and platform credential files
(`.env`, Firebase config files, signing keys) are intentionally **excluded**
from this repository. The bundled **food database** (~18.5k curated entries) is
proprietary and is **also excluded**; only its model and search logic
(`turkish_foods_db.dart`) are shown. The source is published for review,
not as a build-and-run drop-in.

## License

Licensed under the **GNU Affero General Public License v3.0** (AGPL-3.0).
See [`LICENSE`](LICENSE) for the full text. Under AGPL-3.0, anyone who uses,
modifies, or runs this software as a network service must make their complete
corresponding source available under the same license.

Copyright © 2026 Vitra. All rights reserved where not granted by the license above.
