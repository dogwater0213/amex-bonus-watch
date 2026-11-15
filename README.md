# amex-bonus-watch

A daily Claude scheduled task checks for new American Express Membership Rewards
transfer bonuses (US). This repo is its memory and its notification relay.

- `seen.json`: bonuses already known. Only bonuses missing from this list trigger an alert.
- `outbox/*.json`: one file per alert, `{"title": "...", "message": "...", "click": "https://..."}`.
  Pushing a new file here runs the workflow, which posts it to ntfy.
- `.github/workflows/notify.yml` + `scripts/notify.sh`: the relay. The ntfy topic is the
  `NTFY_TOPIC` repository secret; it is never written in the repo.

Manual test: Actions > Notify via ntfy > Run workflow.
