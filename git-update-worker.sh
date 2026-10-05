#!/bin/sh
repo="$1"
results="$2"
log="$3"
name=$(basename "$repo")
old=$(cd "$repo" && git rev-parse HEAD 2>/dev/null)
if [ -f "$repo/.git/FETCH_HEAD" ]; then
	if [ "$(find "$repo/.git/FETCH_HEAD" -mmin -5 2>/dev/null)" ]; then
		echo "[$name] skipped" >> "$log"
		exit
	fi
fi
(cd "$repo" && git remote update >/dev/null 2>&1)
if (cd "$repo" && git pull --rebase >/dev/null 2>&1); then
	:
elif (cd "$repo" && git rebase --abort >/dev/null 2>&1); then
	echo "REBASE_CONFLICT:$repo|" >> "$results"
	echo "[$name] REBASE CONFLICT" >> "$log"
	exit
else
	echo "[$name] FAILED" >> "$log"
	exit
fi
new=$(cd "$repo" && git rev-parse HEAD 2>/dev/null)
[ "$old" = "$new" ] && { echo "[$name] up to date" >> "$log"; exit; }
echo "[$name] UPDATED" >> "$log"
changelog=$(cd "$repo" && git log --oneline --no-merges -3 "$old..$new" 2>/dev/null | tr '\n' ';')
echo "UPDATED:$repo|$changelog" >> "$results"