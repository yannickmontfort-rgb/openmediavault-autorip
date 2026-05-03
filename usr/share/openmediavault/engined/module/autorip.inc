<?php
/**
 * Plugin OMV 7 - AutoRip DVD
 * Module PHP pour OpenMediaVault 7
 */

namespace OMV\Engine\Module;

class AutoRip extends \OMV\Engine\Module\ServiceAbstract
    implements \OMV\Engine\Notify\IListener
{
    public function getName() {
        return 'autorip';
    }

    public function getAlias() {
        return 'autorip';
    }

    public function deployAfter(): array {
        return ['fstab'];
    }

    public function bindListeners(\OMV\Engine\Notify\Dispatcher $dispatcher) {
        $dispatcher->addListener(
            OMV_NOTIFY_MODIFY,
            'org.openmediavault.conf.service.autorip',
            [$this, 'setDirty']
        );
    }
}
