#!/bin/sh
set -eu

case "${1:-}" in
	run)
		./scripts/server-run.sh
		;;
	sync)
		./scripts/server-sync.sh
		;;
	peer-create)
		./scripts/peer-create.sh "${2:-}"
		;;
	peer-delete)
		./scripts/peer-delete.sh "${2:-}"
		;;
	peer-disable)
		./scripts/peer-disable.sh "${2:-}"
		;;
	peer-enable)
		./scripts/peer-enable.sh "${2:-}"
		;;
	peer-show)
		./scripts/peer-show.sh "${2:-}"
		;;
	*)
		echo "Usage: $0 [run|sync|peer-create|peer-delete|peer-disable|peer-enable|peer-show] [peer-name]" >&2
		exit 1
		;;
esac
