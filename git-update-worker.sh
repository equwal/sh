#!/bin/sh
# Worker for git-update-repos: git-update-worker.sh REPO/.git RESULTS
repo=${1%/.git}
results="$2"
name=$(basename "$repo")
old=$(cd "$repo" && git rev-parse HEAD 2>/dev/null)
if [ -f "$repo/.git/FETCH_HEAD" ]; then
	if [ "$(find "$repo/.git/FETCH_HEAD" -mmin -5 2>/dev/null)" ]; then
		echo "[$name] skipped"
		exit
	fi
fi
(cd "$repo" && git remote update >/dev/null 2>&1)
if (cd "$repo" && git pull --rebase >/dev/null 2>&1); then
	:
elif (cd "$repo" && git rebase --abort >/dev/null 2>&1); then
	echo "REBASE_CONFLICT:$repo|" >> "$results"
	echo "[$name] REBASE CONFLICT"
	exit
else
	echo "[$name] FAILED"
	exit
fi
new=$(cd "$repo" && git rev-parse HEAD 2>/dev/null)
[ "$old" = "$new" ] && { echo "[$name] up to date"; exit; }
echo "[$name] UPDATED"
changelog=$(cd "$repo" && git log --oneline --no-merges -3 "$old..$new" 2>/dev/null | tr '\n' ';')
echo "UPDATED:$repo|$changelog" >> "$results"