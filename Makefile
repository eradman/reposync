RELEASE = 1.0

reposync: reposync.sh
	sed -e 's/$${release}/${RELEASE}/' reposync.sh > $@
	@chmod +x $@

install: ${TARGETS}
	@mkdir -p ${DESTDIR}${PREFIX}/bin
	install reposync ${DESTDIR}${PREFIX}/bin/

uninstall:
	rm ${DESTDIR}${PREFIX}/bin/reposync

clean:
	rm -f reposync

.PHONY: reposync
