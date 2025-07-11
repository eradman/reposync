#!/bin/sh -u
#
# 2025 Eric Radman <ericshane@eradman.com>
# low-friction distributed testing

: ${RSYNC:="openrsync"}
: ${RSYNC_ARGS:="--recursive --links --delete --perms"}
: ${RSYNC_EXCLUDE:="git ls-files --exclude-standard -oi --directory"}
: ${RSYNC_QUIET:="1"}
: ${REPOSYNC_DB:="$HOME/reposync.db"}
: ${REPOSYNC_SETUP:="uname -prs; . ~/.profile; set -e"}

trap 'printf "reposync: exit code $? on line $LINENO\n" >&2; exit 1' ERR \
	2> /dev/null || exec bash $0 "$@"

repo=${PWD##$HOME/}
tmp=${SYSTMP:-/tmp}/reposync.$(basename $PWD)

log() {
	printf "\e[38;5;${1}m${2}\e[0m\n"
}
log_inverted() {
	printf "\e[38;5;${1}m\e[7m${2}\e[0m\n"
}

usage() {
	cat >&2 <<-MSG
	release: ${release}
	usage:
	  reposync init|list
	  reposync add host [rsync_path]
	  reposync remove host
	  reposync run 'cmd; cmd; ...'
	MSG
	exit 1
}

[ $# -gt 0 ] || usage
trap 'rm -rf $tmp' EXIT
mkdir $tmp

action=$1
shift
case $action in
	init)
		[ $# -eq 0 ] || usage
		sqlite3 $REPOSYNC_DB <<-SQL
		CREATE TABLE ci (
		  hostname text UNIQUE,
		  rsync_path text DEFAULT('rsync'),
		  last_fail real DEFAULT(unixepoch('now','subsec'))
		)
		SQL
		;;
	list)
		[ $# -eq 0 ] || usage
		sqlite3 $REPOSYNC_DB "SELECT hostname, rsync_path FROM ci ORDER BY hostname"
		;;
	add)
		case $# in
			1)
				sqlite3 $REPOSYNC_DB "INSERT INTO ci (hostname) VALUES ('$1')"
				;;
			2)
				sqlite3 $REPOSYNC_DB "INSERT INTO ci (hostname, rsync_path) VALUES ('$1', '$2')"
				;;
			*)
				usage
				;;
		esac
		;;
	remove)
		[ $# -eq 1 ] || usage
		sqlite3 $REPOSYNC_DB "DELETE FROM ci WHERE hostname='$1'"
		;;
	run)
		[ $# -eq 1 ] || usage
		trap 'log 226 "EXIT $?"; rm -rf $tmp' EXIT
		$RSYNC_EXCLUDE > $tmp/exclude
		
		for host in $(sqlite3 $REPOSYNC_DB "SELECT hostname FROM ci ORDER BY last_fail DESC, hostname"); do
			log_inverted 39 $host
			rsync_path=$(sqlite3 $REPOSYNC_DB "SELECT rsync_path FROM ci WHERE hostname='$host'")
		
			# Sync regular files, not including files ignored by git
			# Don't set file times since this confuses make(1)
			$RSYNC --rsync-path $rsync_path \
					--exclude-from=$tmp/exclude \
					$RSYNC_ARGS . $host:$repo/ > $tmp/out 2> $tmp/err || {
				cat $tmp/out $tmp/err
				exit 1
			}
			[ $RSYNC_QUIET == "1" ] || cat $tmp/out $tmp/err
		
			# Execute remote commands
			ssh $host "$REPOSYNC_SETUP; cd $repo; $*" \
				|| {
					log 196 "FAIL"
					sqlite3 $REPOSYNC_DB "UPDATE ci SET last_fail=unixepoch('now','subsec') WHERE hostname='$host'"
					exit 1
				} \
				&& {
					log 190 "PASS"
				}
		done
		;;
	*)
		usage
		;;
esac
