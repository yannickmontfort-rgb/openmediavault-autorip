<?php
/**
 * Plugin OMV 7 - AutoRip DVD
 * RPC PHP pour OpenMediaVault 7
 */

namespace OMV\Rpc;

class AutoRip extends \OMV\Rpc\ServiceAbstract
{
    private const CONFIG_FILE = '/etc/openmediavault/autorip.conf';
    private const DEVICE_PATTERN = '/^\/dev\/sr[0-9]+$/';

    private function requireParam(array $params, string $name) {
        if (!array_key_exists($name, $params)) {
            throw new \InvalidArgumentException(sprintf("Missing required parameter '%s'.", $name));
        }
        return $params[$name];
    }

    private function normalizeBool($value, string $name): bool {
        if (is_bool($value)) {
            return $value;
        }
        $normalized = filter_var($value, FILTER_VALIDATE_BOOLEAN, FILTER_NULL_ON_FAILURE);
        if (null === $normalized) {
            throw new \InvalidArgumentException(sprintf("Invalid boolean value for '%s'.", $name));
        }
        return $normalized;
    }

    private function normalizeString($value, string $name, bool $allowEmpty = false): string {
        if (!is_string($value)) {
            throw new \InvalidArgumentException(sprintf("Invalid string value for '%s'.", $name));
        }
        $value = trim($value);
        if (!$allowEmpty && '' === $value) {
            throw new \InvalidArgumentException(sprintf("Parameter '%s' must not be empty.", $name));
        }
        return $value;
    }

    private function normalizeInt($value, string $name, int $min, int $max): int {
        if (is_int($value)) {
            $intValue = $value;
        } elseif (is_numeric($value) && (string)(int)$value === (string)$value) {
            $intValue = (int)$value;
        } else {
            throw new \InvalidArgumentException(sprintf("Invalid integer value for '%s'.", $name));
        }
        if ($intValue < $min || $intValue > $max) {
            throw new \InvalidArgumentException(sprintf("Parameter '%s' must be between %d and %d.", $name, $min, $max));
        }
        return $intValue;
    }

    private function normalizeLanguageList($value, string $name): array {
        if (!is_array($value)) {
            throw new \InvalidArgumentException(sprintf("Invalid list value for '%s'.", $name));
        }
        $result = [];
        foreach ($value as $lang) {
            if (!is_string($lang) || !preg_match('/^[a-z]{3}$/', $lang)) {
                throw new \InvalidArgumentException(sprintf("Invalid language code in '%s'.", $name));
            }
            $result[] = $lang;
        }
        return array_values(array_unique($result));
    }

    private function normalizeChoice($value, string $name, array $allowed): string {
        $choice = $this->normalizeString($value, $name);
        if (!in_array($choice, $allowed, true)) {
            throw new \InvalidArgumentException(sprintf("Invalid value for '%s'.", $name));
        }
        return $choice;
    }

    private function getDefaultSettings(): array {
        return [
            'enable' => false,
            'device' => '/dev/sr0',
            'share_path' => '',
            'tmp_dir' => '/tmp/autorip',
            'min_length' => 1200,
            'eject_after' => true,
            'notify_email' => false,
            'audio_languages' => ['fra', 'eng'],
            'subtitle_languages' => ['fra', 'eng'],
            'keep_all_audio' => false,
            'keep_all_subtitles' => false,
            'encode_enabled' => false,
            'encode_codec' => 'x264',
            'encode_quality' => 22,
            'encode_preset' => 'medium',
        ];
    }

    private function loadConfig(): array {
        $defaults = $this->getDefaultSettings();
        if (!file_exists(self::CONFIG_FILE)) {
            return $defaults;
        }
        $raw = file_get_contents(self::CONFIG_FILE);
        if (false === $raw || '' === trim($raw)) {
            return $defaults;
        }
        $config = json_decode($raw, true);
        if (!is_array($config)) {
            return $defaults;
        }
        return array_merge($defaults, $config);
    }

    public function getName() {
        return 'AutoRip';
    }

    public function initialize() {
        $this->registerMethod('getSettings');
        $this->registerMethod('setSettings');
        $this->registerMethod('getLogs');
    }

    public function getSettings($params, $context) {
        $this->validateMethodContext($context, ['role' => \OMV_ROLE_ADMINISTRATOR]);
        $config = $this->loadConfig();
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
            'encode_enabled'     => (bool)($config['encode_enabled'] ?? false),
            'encode_codec'       => $config['encode_codec'] ?? 'x264',
            'encode_quality'     => (int)($config['encode_quality'] ?? 22),
            'encode_preset'      => $config['encode_preset'] ?? 'medium',
        ];
    }

    public function setSettings($params, $context) {
        $this->validateMethodContext($context, ['role' => \OMV_ROLE_ADMINISTRATOR]);

        $enable = $this->normalizeBool($this->requireParam($params, 'enable'), 'enable');
        $device = $this->normalizeString($this->requireParam($params, 'device'), 'device');
        if (!preg_match(self::DEVICE_PATTERN, $device)) {
            throw new \InvalidArgumentException("Invalid DVD device. Expected format like /dev/sr0.");
        }
        $sharefolderref = $this->normalizeString($this->requireParam($params, 'sharefolderref'), 'sharefolderref');
        $tmpDir = $this->normalizeString($this->requireParam($params, 'tmp_dir'), 'tmp_dir');
        if ('/' !== $tmpDir[0]) {
            throw new \InvalidArgumentException("Parameter 'tmp_dir' must be an absolute path.");
        }
        $minLength = $this->normalizeInt($this->requireParam($params, 'min_length'), 'min_length', 60, 86400);
        $ejectAfter = $this->normalizeBool($this->requireParam($params, 'eject_after'), 'eject_after');
        $notifyEmail = $this->normalizeBool($this->requireParam($params, 'notify_email'), 'notify_email');
        $keepAllAudio = $this->normalizeBool($params['keep_all_audio'] ?? false, 'keep_all_audio');
        $keepAllSubtitles = $this->normalizeBool($params['keep_all_subtitles'] ?? false, 'keep_all_subtitles');
        $audioLanguages = $this->normalizeLanguageList($params['audio_languages'] ?? ['fra', 'eng'], 'audio_languages');
        $subtitleLanguages = $this->normalizeLanguageList($params['subtitle_languages'] ?? ['fra', 'eng'], 'subtitle_languages');
        $encodeEnabled = $this->normalizeBool($params['encode_enabled'] ?? false, 'encode_enabled');
        $encodeCodec = $this->normalizeChoice($params['encode_codec'] ?? 'x264', 'encode_codec', ['x264', 'x265']);
        $encodeQuality = $this->normalizeInt($params['encode_quality'] ?? 22, 'encode_quality', 0, 51);
        $encodePreset = $this->normalizeChoice(
            $params['encode_preset'] ?? 'medium',
            'encode_preset',
            ['ultrafast', 'fast', 'medium', 'slow', 'veryslow']
        );

        $config = [
            'enable'             => $enable,
            'device'             => $device,
            'share_path'         => $sharefolderref,
            'tmp_dir'            => $tmpDir,
            'min_length'         => $minLength,
            'eject_after'        => $ejectAfter,
            'notify_email'       => $notifyEmail,
            'audio_languages'    => $audioLanguages,
            'subtitle_languages' => $subtitleLanguages,
            'keep_all_audio'     => $keepAllAudio,
            'keep_all_subtitles' => $keepAllSubtitles,
            'encode_enabled'     => $encodeEnabled,
            'encode_codec'       => $encodeCodec,
            'encode_quality'     => $encodeQuality,
            'encode_preset'      => $encodePreset,
        ];

        $written = file_put_contents(self::CONFIG_FILE, json_encode($config, JSON_PRETTY_PRINT));
        if (false === $written) {
            throw new \RuntimeException('Failed to write AutoRip configuration.');
        }
        return null;
    }

    public function getLogs($params, $context) {
        $this->validateMethodContext($context, ['role' => \OMV_ROLE_ADMINISTRATOR]);
        $logFile = '/var/log/autorip.log';
        if (!file_exists($logFile)) return ['logs' => 'Aucun log disponible.'];
        $lines = array_slice(file($logFile), -100);
        return ['logs' => implode('', $lines)];
    }
}
