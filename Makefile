PACKAGE_NAME = openmediavault-autorip
PACKAGE_VERSION = 1.0.0
ARCH = all
DEB = $(PACKAGE_NAME)_$(PACKAGE_VERSION)_$(ARCH).deb
STAGING = /tmp/$(PACKAGE_NAME)-staging

.PHONY: build install clean

build:
	@echo "Construction du paquet Debian..."
	@test -n "$(STAGING)" || (echo "STAGING is not set"; exit 1)
	rm -rf $(STAGING)
	mkdir -p $(STAGING)/DEBIAN
	find . -mindepth 1 -maxdepth 1 -not -name 'DEBIAN' -not -name 'debian' \
		-not -name '.*' -not -name 'Makefile' -not -name 'README*' \
		-not -name '*.deb' | xargs -I{} cp -r {} $(STAGING)/
	cp -r debian/. $(STAGING)/DEBIAN/
	chmod 755 $(STAGING)/DEBIAN/postinst $(STAGING)/DEBIAN/prerm || true
	dpkg-deb --build $(STAGING) $(DEB)
	rm -rf $(STAGING)
	@echo "Paquet créé : $(DEB)"

install:
	@echo "Installation du plugin OMV AutoRip..."
	dpkg -i $(DEB)
	omv-salt deploy run omvextras || true
	@echo "Installation terminée."

clean:
	rm -f $(DEB)
