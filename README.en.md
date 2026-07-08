# Baseball LIVE KR

<p align="center">
  <img src="images/logo-concepts/baseball-live-kr-logo-scorecard-korean-baseball-no-bg-symbols.png" alt="Baseball LIVE KR app logo" width="160">
</p>

<p align="center">
  <a href="README.md">한국어</a> · <b>English</b>
</p>

Baseball LIVE KR lets you follow how a game is unfolding without keeping the broadcast running. It surfaces today's KBO game status in always-visible places like widgets, Live Activities, and the menu bar, so you can catch score changes and your team's momentum without opening the app.

Right now we're polishing the macOS experience first — checking game status from the menu bar and a small window. An iOS (iPhone) version, including widgets and Live Activities, is planned next.

## What you can do today

### Follow games

- Browse today's KBO games and per-game scores
- Check the current situation and inning-by-inning flow of live games
- Follow both teams' momentum in the game detail view

macOS app main screen:

<img src="images/main.png" alt="Baseball LIVE KR main screen" width="720">

### View records

- Check team standings and key stats
- Search players and view season records
- Team logos and wordmarks to spot your team faster

### Follow along easily

- Get a game summary from the menu bar without opening the full app
- Don't miss score and situation changes even if you rarely open the screen

Checking a game from the menu bar:

<img src="images/menubar.png" alt="Baseball LIVE KR menu bar screen" width="360">

## How to run the app

Download the latest `BaseballLiveKR-0.1.0-macOS.dmg` from GitHub Releases.

1. Open the `.dmg` file and drag the large `BaseballLiveKR.app` icon on the left into the `Applications` folder on the right.
2. Open `BaseballLiveKR.app` from `Applications`.
3. On first launch you'll see the security warning "Apple could not verify 'BaseballLiveKR' is free of malware." This is expected because the build has not yet been notarized by Apple. Follow the steps below once and you won't be asked again.
   1. In the warning dialog, click `Done`. (Do not click `Move to Trash`.)

      <img src="images/error.png" alt="Baseball LIVE KR launch error" width="360">

   2. Open `System Settings` > `Privacy & Security`, then click `Open Anyway` under the `Security` section below.

      <img src="images/settings.png" alt="Baseball LIVE KR settings screen" width="360">

   3. In the confirmation dialog, click `Open Anyway` again and authenticate with your admin password or Touch ID.

   If you prefer the terminal, a single line does the same thing:

   ```bash
   xattr -d com.apple.quarantine /Applications/BaseballLiveKR.app
   ```

4. Click the Baseball LIVE KR icon in the menu bar to check today's games.

## Development & verification

Detailed commands for development, verification, and release preparation live in `docs/dev.md`.

## Roadmap

- Make new-version alerts and update guidance feel more natural
- Streamline distribution so the macOS app is easier to download and run
- Build a screen to quickly see today's and favorite games on iPhone
- Follow the flow of a game right away through widgets and Live Activities
- Improve data quality so scores and stats stay reliable during live games
- Personalize the experience so you can check your team's games even faster
