RELEASE = 1.1
PREFIX ?= /usr/local
MANPREFIX ?= ${PREFIX}/man

reposync: reposync.sh
	sed -e 's/$${release}/${RELEASE}/' reposync.sh > $@
	@chmod +x $@

check: reposync
	@./system_test.sh

install: ${TARGETS}
	@mkdir -p ${DESTDIR}${PREFIX}/bin
	install reposync ${DESTDIR}${PREFIX}/bin/
	install -m 644 reposync.1 ${DESTDIR}${MANPREFIX}/man1

uninstall:
	rm ${DESTDIR}${PREFIX}/bin/reposync
	rm ${DESTDIR}${MANPREFIX}/man1/reposync.1

clean:
	rm -f reposync

.PHONY: reposync
