PACKAGE_NAME = openmediavault-autorip
PACKAGE_VERSION = 1.0.0
ARCH = all
DEB = $(PACKAGE_NAME)_$(PACKAGE_VERSION)_$(ARCH).deb
STAGING = /tmp/$(PACKAGE_NAME)-staging

.PHONY: build deps install clean

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

deps:
	@echo "Ajout du dépôt MakeMKV..."
	apt-get install -y curl gnupg ca-certificates python3
	KEY_FP=$$(curl -fsSL "https://api.launchpad.net/1.0/~heyarje/+archive/makemkv-beta" \
		| python3 -c "import sys,json; print(json.load(sys.stdin)['signing_key_fingerprint'])") && \
	curl -fsSL "https://keyserver.ubuntu.com/pks/lookup?op=get&search=0x$$KEY_FP" \
		| gpg --dearmor -o /etc/apt/trusted.gpg.d/makemkv-beta.gpg
	echo "deb https://ppa.launchpadcontent.net/heyarje/makemkv-beta/ubuntu jammy main" \
		> /etc/apt/sources.list.d/makemkv-beta.list
	apt-get update -q

install: deps
	@echo "Installation du plugin OMV AutoRip..."
	apt-get install -y ./$(DEB)
	omv-salt deploy run omvextras || true
	@echo "Installation terminée."

clean:
	rm -f $(DEB)
