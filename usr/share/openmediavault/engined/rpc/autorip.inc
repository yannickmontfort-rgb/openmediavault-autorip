<?php
/**
 * Plugin OMV 7 - AutoRip DVD
 * RPC PHP pour OpenMediaVault 7
 */

namespace OMV\Rpc;

class AutoRip extends \OMV\Rpc\ServiceAbstract
{
    public function getName() {
        return 'AutoRip';
    }

    public function initialize() {
        $this->registerMethod('getSettings');
        $this->registerMethod('setSettings');
        $this->registerMethod('getLogs');
    }

    /**
     * Récupère la configuration AutoRip.
     */
    public function getSettings($params, $context) {
        $this->validateMethodContext($context, [
            'role' => OMV_ROLE_ADMINISTRATOR
        ]);

        $configFile = '/etc/openmediavault/autorip.conf';
        $config = json_decode(file_get_contents($configFile), true);

        return [
            'enable'             => (bool)$config['enable'],
            'device'             => $config['device'],
            'sharefolderref'     => $config['share_path'],
            'tmp_dir'            => $config['tmp_dir'],
            'min_length'         => (int)$config['min_length'],
            'eject_after'        => (bool)$config['eject_after'],
            'notify_email'       => (bool)$config['notify_email'],
            'audio_languages'    => $config['audio_languages'] ?? ['fra', 'eng'],
            'subtitle_languages' => $config['subtitle_languages'] ?? ['fra', 'eng'],
            'keep_all_audio'     => (bool)($config['keep_all_audio'] ?? false),
            'keep_all_subtitles' => (bool)($config['keep_all_subtitles'] ?? false),
        ];
    }

    /**
     * Sauvegarde la configuration AutoRip.
     */
    public function setSettings($params, $context) {
        $this->validateMethodContext($context, [
            'role' => OMV_ROLE_ADMINISTRATOR
        ]);

        $this->validateMethodParams($params, 'rpc.autorip.setsettings');

        $config = [
            'enable'             => (bool)$params['enable'],
            'device'             => $params['device'],
            'share_path'         => $params['sharefolderref'],
            'tmp_dir'            => $params['tmp_dir'],
            'min_length'         => (int)$params['min_length'],
            'eject_after'        => (bool)$params['eject_after'],
            'notify_email'       => (bool)$params['notify_email'],
            'audio_languages'    => $params['audio_languages'] ?? ['fra', 'eng'],
            'subtitle_languages' => $params['subtitle_languages'] ?? ['fra', 'eng'],
            'keep_all_audio'     => (bool)($params['keep_all_audio'] ?? false),
            'keep_all_subtitles' => (bool)($params['keep_all_subtitles'] ?? false),
        ];

        file_put_contents(
            '/etc/openmediavault/autorip.conf',
            json_encode($config, JSON_PRETTY_PRINT)
        );

        return null;
    }

    /**
     * Récupère les logs AutoRip.
     */
    public function getLogs($params, $context) {
        $this->validateMethodContext($context, [
            'role' => OMV_ROLE_ADMINISTRATOR
        ]);

        $logFile = '/var/log/autorip.log';
        if (!file_exists($logFile)) {
            return ['logs' => 'Aucun log disponible.'];
        }

        $lines = array_slice(file($logFile), -100);
        return ['logs' => implode('', $lines)];
    }
}
