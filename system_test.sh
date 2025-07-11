#!/bin/sh
set -a

PATH="$PWD/test/stubs:$PATH"
REPOSYNC_DB="test/reposync.db"
RSYNC_QUIET=0

reset() {
	rm -f $REPOSYNC_DB
}

try() {
	printf '.'
	expected="test/expected/$(printf "$1" | tr -c '[:alnum:]' '_')"
}

check() {
	git diff --exit-code $expected.* || exit 1
	let tests+=1
}

# setup
trap 'rm -f $REPOSYNC_DB' EXIT


try "initial setup"
	reset
	./reposync init
	./reposync add alpine
	./reposync add freebsd openrsync
	./reposync add macmini-m1
	./reposync list > $expected.out
	check

try "run once"
	reset
	./reposync init
	sqlite3 $REPOSYNC_DB <<-SQL
		INSERT INTO ci (hostname, last_fail) VALUES
		  ('alpine', 1751388697.871),
		  ('bhyve1', 1751388697.871);
	SQL
	./reposync run 'hostname' > $expected.out
	check

try "run fail run again"
	reset
	./reposync init
	sqlite3 $REPOSYNC_DB <<-SQL
		INSERT INTO ci (hostname, last_fail) VALUES
		  ('alpine', 1751388697.871),
		  ('bhyve1', 1751388697.871),
		  ('macmini-m1', 1751388697.871);
	SQL
	./reposync run 'hostname' > $expected.out
	./reposync run 'hostname' >> $expected.out
	check

echo
echo "$tests tests PASSED"
