# SkillCubes

Flutter mobile app for cognitive assessment & interview test prep
(P&G, Cut-e / Aon, FlowQ, Pymetrics style).

**Package:** `com.qybit.skillcubes`

## Run

```bash
flutter pub get
dart run flutter_launcher_icons
flutter run
```

## Features

- Dark / Light theme (Profile toggle)
- TR / EN localization (`assets/translations/`)
- Auth: Splash, Login, Sign Up
- Games: Funnel, Pattern, Quick Math, Ratio, Charts, Go/No-Go
- Classic problems with hints & solutions
- Marathon exam simulation
- Leaderboards & profile (streaks, badges)

## Structure

```
lib/
  core/          theme, localization, router, stats, widgets
  features/
    auth/        splash, login, signup
    dashboard/   bottom nav shell
    games/       cognitive & speed modules
    problems/    standard exam problems
    marathon/    timed mixed simulation
    leaderboard/ rankings
    profile/     settings, badges, theme & language
```

## Branding

Logo: `assets/images/skillcubes_logo.png`
