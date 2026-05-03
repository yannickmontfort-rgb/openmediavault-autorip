PACKAGE_NAME = openmediavault-autorip
PACKAGE_VERSION = 1.0.0
ARCH = all
DEB = $(PACKAGE_NAME)_$(PACKAGE_VERSION)_$(ARCH).deb

.PHONY: build install clean

build:
	@echo "Construction du paquet Debian..."
	dpkg-deb --build . $(DEB)
	@echo "Paquet créé : $(DEB)"

install:
	@echo "Installation du plugin OMV AutoRip..."
	dpkg -i $(DEB)
	omv-salt deploy run omvextras || true
	@echo "Installation terminée."

clean:
	rm -f $(DEB)
