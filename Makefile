PACKAGE_NAME = openmediavault-autorip
PACKAGE_VERSION = 1.0.3
ARCH = all
DEB = $(PACKAGE_NAME)_$(PACKAGE_VERSION)_$(ARCH).deb
PKGROOT = .pkgroot

.PHONY: build install clean deploy-check collect-500-debug

build:
	@echo "Construction du paquet Debian..."
	rm -rf $(PKGROOT)
	mkdir -p $(PKGROOT)/DEBIAN
	cp debian/control $(PKGROOT)/DEBIAN/control
	cp debian/postinst $(PKGROOT)/DEBIAN/postinst
	cp debian/prerm $(PKGROOT)/DEBIAN/prerm
	chmod 755 $(PKGROOT)/DEBIAN/postinst $(PKGROOT)/DEBIAN/prerm
	mkdir -p $(PKGROOT)/srv/autorip
	cp -a srv/autorip/. $(PKGROOT)/srv/autorip/
	mkdir -p $(PKGROOT)/etc/udev/rules.d
	cp etc/udev/rules.d/99-dvd-autorip.rules $(PKGROOT)/etc/udev/rules.d/
	mkdir -p $(PKGROOT)/etc/openmediavault
	cp etc/openmediavault/autorip.conf $(PKGROOT)/etc/openmediavault/
	mkdir -p $(PKGROOT)/etc/systemd/system
	cp etc/systemd/system/autorip.service $(PKGROOT)/etc/systemd/system/
	mkdir -p $(PKGROOT)/usr/share/openmediavault/engined/module
	cp usr/share/openmediavault/engined/module/autorip.inc $(PKGROOT)/usr/share/openmediavault/engined/module/
	mkdir -p $(PKGROOT)/usr/share/openmediavault/engined/rpc
	cp usr/share/openmediavault/engined/rpc/autorip.inc $(PKGROOT)/usr/share/openmediavault/engined/rpc/
	mkdir -p $(PKGROOT)/usr/share/openmediavault/workbench/component.d
	cp usr/share/openmediavault/workbench/component.d/*.yaml $(PKGROOT)/usr/share/openmediavault/workbench/component.d/
	mkdir -p $(PKGROOT)/usr/share/openmediavault/workbench/route.d
	cp usr/share/openmediavault/workbench/route.d/*.yaml $(PKGROOT)/usr/share/openmediavault/workbench/route.d/
	mkdir -p $(PKGROOT)/usr/share/openmediavault/workbench/navigation.d
	cp usr/share/openmediavault/workbench/navigation.d/*.yaml $(PKGROOT)/usr/share/openmediavault/workbench/navigation.d/
	dpkg-deb --build $(PKGROOT) $(DEB)
	@echo "Paquet créé : $(DEB)"

install:
	@echo "Installation du plugin OMV AutoRip..."
	dpkg -i $(DEB)
	omv-salt deploy run nginx || true
	@echo "Installation terminée."

clean:
	rm -f $(DEB)
	rm -rf $(PKGROOT)

deploy-check: clean build install
	@echo "Redemarrage des services OMV..."
	systemctl restart omv-engined
	systemctl restart nginx
	@PHP_FPM_SVC=$$(systemctl list-unit-files | awk '/^php8\.[0-9]+-fpm\.service/ {print $$1; exit}'); \
	if [ -n "$$PHP_FPM_SVC" ]; then \
		echo "Redemarrage $$PHP_FPM_SVC..."; \
		systemctl restart "$$PHP_FPM_SVC"; \
	else \
		echo "Aucun service php-fpm detecte automatiquement."; \
	fi
	chmod +x tools/check_post_install.sh
	./tools/check_post_install.sh

collect-500-debug:
	chmod +x tools/collect_omv_500_debug.sh
	./tools/collect_omv_500_debug.sh
