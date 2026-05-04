PACKAGE_NAME = openmediavault-autorip
PACKAGE_VERSION = 1.0.0
ARCH = all
DEB = $(PACKAGE_NAME)_$(PACKAGE_VERSION)_$(ARCH).deb
STAGING = /tmp/$(PACKAGE_NAME)-staging

.PHONY: build deps install uninstall clean

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
	@echo "Nettoyage de l'état cassé éventuel du paquet précédent..."
	dpkg --remove --force-remove-reinstreq $(PACKAGE_NAME) 2>/dev/null || true
	@echo "Installation des dépendances de construction du paquet..."
	apt-get update -q || echo "Avertissement : apt-get update a rencontré des erreurs (dépôts pré-existants ignorés)" >&2
	apt-get install -y dpkg-dev
	@echo "Installation des dépendances de MakeMKV..."
	if ! command -v makemkvcon > /dev/null 2>&1; then \
		apt-get install -y curl wget build-essential pkg-config libc6-dev libssl-dev \
			libexpat1-dev libavcodec-dev libgl1-mesa-dev qtbase5-dev zlib1g-dev; \
		MAKEMKV_VER=$$(curl -fsSL "https://www.makemkv.com/forum/viewtopic.php?f=3&t=224" \
			| grep -oP '(?<=MakeMKV v)[0-9.]+' | head -1) || true; \
		if [ -n "$$MAKEMKV_VER" ]; then \
			TMP_DIR=$$(mktemp -d); \
			( \
				cd "$$TMP_DIR" && \
				wget -q "https://www.makemkv.com/download/makemkv-oss-$${MAKEMKV_VER}.tar.gz" && \
				wget -q "https://www.makemkv.com/download/makemkv-bin-$${MAKEMKV_VER}.tar.gz" && \
				tar -xf "makemkv-oss-$${MAKEMKV_VER}.tar.gz" && \
				cd "makemkv-oss-$${MAKEMKV_VER}" && \
				./configure && make && make install && \
				cd "$$TMP_DIR" && \
				tar -xf "makemkv-bin-$${MAKEMKV_VER}.tar.gz" && \
				cd "makemkv-bin-$${MAKEMKV_VER}" && \
				make && make install \
			) || echo "Avertissement : compilation de MakeMKV échouée" >&2; \
			rm -rf "$$TMP_DIR"; \
		else \
			echo "Avertissement : version MakeMKV introuvable, installation ignorée" >&2; \
		fi; \
	fi
	@echo "Installation de libdvdcss2..."
	if ! dpkg -l libdvdcss2 2>/dev/null | grep -q '^ii'; then \
		apt-get install -y --allow-unauthenticated libdvdcss2 || true; \
	fi

install: deps
	@echo "Installation du plugin OMV AutoRip..."
	dpkg -i ./$(DEB) || apt-get install -f -y
	omv-salt deploy run nginx || true
	systemctl restart openmediavault-engined || true
	@echo "Installation terminée."

uninstall:
	@echo "Désinstallation du plugin OMV AutoRip..."
	dpkg -r $(PACKAGE_NAME) || true
	omv-salt deploy run nginx || true
	systemctl restart openmediavault-engined || true
	@echo "Désinstallation terminée."

clean:
	rm -f $(DEB)
