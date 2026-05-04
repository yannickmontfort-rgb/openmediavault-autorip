PACKAGE_NAME = openmediavault-autorip
PACKAGE_VERSION = 1.0.3
ARCH = all
DEB = $(PACKAGE_NAME)_$(PACKAGE_VERSION)_$(ARCH).deb

.PHONY: build install clean deploy-check collect-500-debug

build:
	@echo "Construction du paquet Debian..."
	dpkg-deb --build . $(DEB)
	@echo "Paquet créé : $(DEB)"

install:
	@echo "Installation du plugin OMV AutoRip..."
	dpkg -i $(DEB)
	omv-salt deploy run nginx || true
	@echo "Installation terminée."

clean:
	rm -f $(DEB)

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
