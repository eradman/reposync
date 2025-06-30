Low-Friction Distributed Testing
================================

A minimalist CI/CD utility for replicating a local repository to remote hosts for
regression testing.

Features:

* Try regressions without having to commit changes
* Files marked by `.gitignore` are not replicated
* Subsequent invocations prioritize last host to fail

Dependencies
------------

* sqlite3
* git
* rsync / openrsync

Installation
------------

    make install

Or to specify a specific installation location

    PREFIX=$HOME/local make install

News
----

Notification of new releases are provided by an
[Atom feed](https://github.com/eradman/reposync/releases.atom),
and release history is covered in the [NEWS](NEWS) file.
