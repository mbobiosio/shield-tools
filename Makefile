# shield-tools, from the command line.
#
# Shortcuts for the read-only and everyday steps. Anything that changes the device
# (`--apply`) is deliberately left out: type the script yourself so you see what you run.
#
# `make` on its own lists what there is.

.DEFAULT_GOAL := help
.PHONY: help connect devices backup backup-state debloat-dry-run restore-dry-run \
	launcher reboot lint

SHELLCHECK ?= shellcheck
SHIELD ?=

# SHIELD=<ip> or <ip>:<port> picks the device for every target (adb reads ANDROID_SERIAL).
ifneq ($(SHIELD),)
export ANDROID_SERIAL := $(if $(findstring :,$(SHIELD)),$(SHIELD),$(SHIELD):5555)
endif

help: ## List what there is
	@grep -hE '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) \
		| awk 'BEGIN {FS = ":.*?## "}; {printf "  \033[36m%-16s\033[0m %s\n", $$1, $$2}'
	@echo ""
	@echo "  SHIELD=<ip> picks the device, e.g. make connect SHIELD=192.168.1.20"

## ── Device ─────────────────────────────────────────────────────────

connect: ## Connect to the SHIELD over the network (needs SHIELD=<ip>)
	@test -n "$(SHIELD)" || { echo "usage: make connect SHIELD=<shield-ip>"; exit 1; }
	@adb connect $(ANDROID_SERIAL)
	@adb devices

devices: ## List connected devices
	@adb devices

backup: ## Snapshot package state and APKs of user-installed apps
	@./shield-backup.sh

backup-state: ## Snapshot package state only (fast, no APKs)
	@./shield-backup.sh --no-apks

debloat-dry-run: ## Show what ./shield-debloat.sh --apply would change
	@./shield-debloat.sh

restore-dry-run: ## Show what ./shield-restore.sh --apply would change (latest backup)
	@./shield-restore.sh

launcher: ## Show the default launcher and the ones available
	@./shield-launcher.sh status

reboot: ## Reboot the SHIELD (frees memory held by stopped services)
	@adb reboot

## ── Development ────────────────────────────────────────────────────

lint: ## shellcheck every script (what CI runs)
	@command -v $(SHELLCHECK) >/dev/null || { echo "shellcheck not found: brew install shellcheck"; exit 1; }
	@$(SHELLCHECK) *.sh
	@echo "shellcheck: ok"
