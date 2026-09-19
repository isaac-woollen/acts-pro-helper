# Acts Pro Helper

Acts Pro Helper is a lightweight Bash utility for church media teams using ProPresenter and ACTS. It watches the current slide text from ProPresenter, detects Bible references, and triggers a configured look automatically. It also watches a countdown music folder and copies updated audio files into ProPresenter's media asset directory.

This project is designed to reduce manual work during worship services by handling repeatable, rule-based actions in the background.

## What it does

This script runs two background loops:

1. Slide monitoring loop
   - Polls `http://${HOST}:${PORT}/v1/status/slide`
   - Detects whether the current slide text looks like a Bible reference
   - Triggers a configured ProPresenter look such as `Scripture`

2. Countdown music update loop
   - Watches a configured music folder for an `update.file`
   - Reads the new filename from that file
   - Copies the file into ProPresenter's media assets directory
   - Renames the update marker to `.backup.txt` so it is not processed repeatedly

## Features

- Automatically detects Bible references in slide text
- Triggers a ProPresenter look without manual intervention
- Supports updating countdown music files from a watched directory
- Persists configuration in a user-level config file
- Logs activity to a local log file under `~/.acts-pro-helper`
- Can be stopped by creating `/tmp/acts-pro-helper.stop`

## Requirements

- macOS or another Unix-like environment with Bash
- `curl` installed
- A ProPresenter instance reachable at the configured host and port
- A ProPresenter look name matching your stage/layout setup

## Installation

1. Clone or download this repository.
2. Make the script executable:

```bash
chmod +x acts-pro-helper.sh
```

3. Start the script:

```bash
./acts-pro-helper.sh
```

The script creates its config file automatically the first time it runs if it does not already exist:

```bash
~/.acts-pro-helper/config.conf
```

## Configuration

The default configuration file looks like this:

```bash
HOST="localhost"
PORT="49888"
SCRIPTURE_LOOK="Scripture"
NEW_COUNTDOWN_MUSIC_DIRECTORY="$HOME/Dropbox/ACTS Dropbox/ACTS Audio/Countdown Music"
PRO_MEDIA_DIRECTORY="$HOME/Library/Application Support/RenewedVision/ProPresenter/UserWorkspaces/ProPresenter/Media/Assets"
```

### Settings

- `HOST`: Hostname or IP of the machine running ProPresenter
- `PORT`: ProPresenter API port, default `49888`
- `SCRIPTURE_LOOK`: ProPresenter look name to trigger when a Bible reference is detected
- `NEW_COUNTDOWN_MUSIC_DIRECTORY`: Folder to watch for new countdown audio files
- `PRO_MEDIA_DIRECTORY`: ProPresenter media asset directory where countdown audio should be copied

You can edit the file at `~/.acts-pro-helper/config.conf` to suit your environment.

## Runtime behavior

On startup, the script:

- creates the config directory if missing
- creates a config file with defaults if needed
- loads configuration values
- sets up a log file at `~/.acts-pro-helper/acts-pro-helper.log`
- starts the background monitoring loops
- waits indefinitely until interrupted or a stop file is detected

## Stopping the script

Create the stop file to exit gracefully:

```bash
touch /tmp/acts-pro-helper.stop
```

The script checks for this file on each loop iteration and exits cleanly after removing it.

## Logs

Activity is written to:

```bash
~/.acts-pro-helper/acts-pro-helper.log
```

This is useful for checking when the script triggers a look or when countdown music files are updated.

## Notes

- The Bible detection regex is intentionally simple and tuned for common slide text like `John 3:16` or `Psalm 23:1-6`.
- The script assumes a ProPresenter API at the configured host and port is available.
- Countdown updates require a file named `update.file` in the watched directory containing the new music filename.

## Example workflow

1. Configure `HOST`, `PORT`, and `SCRIPTURE_LOOK`.
2. Put countdown music updates in the configured music folder with an `update.file` marker.
3. Launch the script in a terminal or as a background process.
4. As slides containing Bible references appear, the configured look is triggered automatically.

## Future roadmap

This project is intentionally a lightweight proof of concept, but the long-term direction is to rebuild it as a more maintainable and feature-rich application.

### Planned rewrite

- Rebuild the application in TypeScript
- Use Deno for the runtime, tooling, and dependency model
- Move from shell scripting to a structured application architecture
- Add stronger configuration validation, logging, and error handling

### Planned UI and automation features

- Add a web UI for configuration and monitoring
- Add a job scheduler for recurring media and automation tasks
- Support richer rule definitions beyond simple Bible-reference detection
- Provide a dashboard for ProPresenter status, triggers, and media updates

This roadmap keeps the current script as the working baseline while laying out the next generation of the product.

## License

This project is licensed under the MIT License. See the [LICENSE](LICENSE) file for the full text.

Copyright (c) 2026
