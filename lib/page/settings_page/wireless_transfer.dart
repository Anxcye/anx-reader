import 'dart:async';
import 'dart:io';

import 'package:anx_reader/config/shared_preference_provider.dart';
import 'package:anx_reader/l10n/generated/L10n.dart';
import 'package:anx_reader/service/wireless_transfer_server.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:anx_reader/widgets/common/container/filled_container.dart';

class WirelessTransferPage extends ConsumerStatefulWidget {
  const WirelessTransferPage({super.key});

  @override
  ConsumerState<WirelessTransferPage> createState() =>
      _WirelessTransferPageState();
}

class _WirelessTransferPageState extends ConsumerState<WirelessTransferPage> {
  bool _isRunning = false;
  List<_TransferAddress> _addresses = const [];
  int _port = 0;
  Timer? _statusTimer;

  @override
  void initState() {
    super.initState();
    _refreshLocalAddresses();
    _updateStatus();
    _statusTimer = Timer.periodic(const Duration(seconds: 2), (_) {
      if (mounted) _updateStatus();
    });
  }

  @override
  void dispose() {
    _statusTimer?.cancel();
    super.dispose();
  }

  void _updateStatus() {
    final server = WirelessTransferServer();
    setState(() {
      _isRunning = server.isRunning;
      _port = server.port;
    });
  }

  Future<void> _refreshLocalAddresses() async {
    final addresses = <_TransferAddress>[];
    try {
      final interfaces = await NetworkInterface.list(
        type: InternetAddressType.IPv4,
        includeLoopback: false,
        includeLinkLocal: false,
      );
      for (final interface in interfaces) {
        for (final addr in interface.addresses) {
          if (!_isUsableIPv4(addr.address)) continue;
          addresses.add(_TransferAddress(
            address: addr.address,
            interfaceName: interface.name,
          ));
        }
      }

      addresses.sort((a, b) => _addressPriority(a).compareTo(
            _addressPriority(b),
          ));
    } catch (e) {
      // ignore
    }
    if (mounted) {
      setState(() {
        _addresses = addresses.isEmpty
            ? const [
                _TransferAddress(
                  address: '127.0.0.1',
                  interfaceName: 'Local',
                ),
              ]
            : addresses;
      });
    }
  }

  Future<void> _toggleServer(bool value) async {
    final server = WirelessTransferServer();
    if (value) {
      final success = await server.start();
      if (success && mounted) {
        setState(() => _isRunning = true);
        _updateStatus();
        await _refreshLocalAddresses();
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(L10n.of(context).commonFailed)),
        );
      }
    } else {
      await server.stop();
      if (mounted) setState(() => _isRunning = false);
    }
  }

  Future<void> _copyAddress(String address) async {
    await Clipboard.setData(ClipboardData(text: address));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_addressCopiedTip(L10n.of(context)))),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = L10n.of(context);
    final theme = Theme.of(context);
    final addresses = _isRunning
        ? _addresses.map((item) => 'http://${item.address}:$_port').toList()
        : <String>[];
    final primaryAddress = addresses.isNotEmpty ? addresses.first : '';

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.settingsWirelessTransfer),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Server toggle card
            FilledContainer(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 34,
                          height: 34,
                          decoration: BoxDecoration(
                            color: _isRunning
                                ? Colors.green.withValues(alpha: 0.14)
                                : theme.colorScheme.secondary
                                    .withValues(alpha: 0.14),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            Icons.wifi_tethering,
                            size: 18,
                            color: _isRunning
                                ? Colors.green
                                : theme.colorScheme.secondary,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              l10n.settingsWirelessTransferStatus,
                              style: theme.textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Text(
                              _isRunning
                                  ? l10n.settingsWirelessTransferRunning
                                  : l10n.settingsWirelessTransferStopped,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: _isRunning
                                    ? Colors.green
                                    : theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    Switch(
                      value: _isRunning,
                      onChanged: _toggleServer,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            if (_isRunning) ...[
              FilledContainer(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.link,
                              size: 18, color: theme.colorScheme.primary),
                          const SizedBox(width: 8),
                          Text(
                            l10n.settingsWirelessTransferAddress,
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      GestureDetector(
                        onTap: primaryAddress.isEmpty
                            ? null
                            : () => _copyAddress(primaryAddress),
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.surfaceContainerHighest
                                .withValues(alpha: 0.5),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  primaryAddress,
                                  style: theme.textTheme.bodyLarge?.copyWith(
                                    fontFamily: 'monospace',
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                              Icon(Icons.copy,
                                  size: 18, color: theme.colorScheme.primary),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      if (addresses.length > 1) ...[
                        Text(
                          _secondaryAddressTip(l10n),
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: 8),
                        ...List.generate(_addresses.length, (index) {
                          final item = _addresses[index];
                          final address = 'http://${item.address}:$_port';
                          if (index == 0) return const SizedBox.shrink();
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: _AddressTile(
                              address: address,
                              interfaceName: item.interfaceName,
                              onCopy: () => _copyAddress(address),
                            ),
                          );
                        }),
                        const SizedBox(height: 4),
                      ],
                      Text(
                        l10n.settingsWirelessTransferStartTip,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],

            FilledContainer(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.info_outline,
                      size: 18,
                      color: theme.colorScheme.primary,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _platformHint(l10n),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                          height: 1.5,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Auto shutdown setting
            FilledContainer(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.timer_outlined,
                            size: 18, color: theme.colorScheme.primary),
                        const SizedBox(width: 8),
                        Text(
                          l10n.settingsWirelessTransferAutoShutdown,
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<int>(
                      initialValue: Prefs().wirelessTransferAutoShutdown,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        contentPadding:
                            EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                      items: [
                        DropdownMenuItem(
                          value: 300,
                          child:
                              Text(l10n.settingsWirelessTransferShutdown5Min),
                        ),
                        DropdownMenuItem(
                          value: 600,
                          child:
                              Text(l10n.settingsWirelessTransferShutdown10Min),
                        ),
                        DropdownMenuItem(
                          value: 1800,
                          child:
                              Text(l10n.settingsWirelessTransferShutdown30Min),
                        ),
                        DropdownMenuItem(
                          value: 0,
                          child:
                              Text(l10n.settingsWirelessTransferShutdownNever),
                        ),
                      ],
                      onChanged: (value) {
                        if (value != null) {
                          Prefs().wirelessTransferAutoShutdown = value;
                        }
                      },
                    ),
                    const SizedBox(height: 8),
                    Text(
                      l10n.settingsWirelessTransferShutdownTip,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  bool _isUsableIPv4(String address) {
    return !address.startsWith('127.') && !address.startsWith('169.254.');
  }

  int _addressPriority(_TransferAddress address) {
    final name = address.interfaceName.toLowerCase();
    final value = address.address;
    if (name.contains('wlan') ||
        name.contains('wi-fi') ||
        name.contains('wifi')) {
      return 0;
    }
    if (name.startsWith('en') || name.contains('ethernet')) return 1;
    if (name.contains('bridge') ||
        name.contains('docker') ||
        name.contains('vmnet') ||
        name.contains('virtual') ||
        name.contains('vbox')) {
      return 9;
    }
    if (value.startsWith('192.168.') ||
        value.startsWith('10.') ||
        RegExp(r'^172\.(1[6-9]|2\d|3[0-1])\.').hasMatch(value)) {
      return 2;
    }
    return 5;
  }

  bool _isChinese(L10n l10n) => l10n.localeName.startsWith('zh');

  String _secondaryAddressTip(L10n l10n) {
    return _isChinese(l10n)
        ? '如果主地址无法访问，请尝试下面其他地址：'
        : 'If the primary address is not reachable, try another address below:';
  }

  String _addressCopiedTip(L10n l10n) {
    return _isChinese(l10n) ? '地址已复制' : 'Address copied';
  }

  String _platformHint(L10n l10n) {
    final isChinese = _isChinese(l10n);
    if (Platform.isIOS) {
      return isChinese
          ? 'iOS 支持无线传书。首次开启时请允许“本地网络”权限，并保持 Anx Reader 在前台。'
          : 'Wireless transfer is supported on iOS. Allow Local Network access on first use and keep Anx Reader in the foreground.';
    }
    if (Platform.isAndroid) {
      return isChinese
          ? 'Android 支持无线传书。请确认手机和浏览器设备在同一 Wi-Fi；部分系统需要关闭省电限制后才能稳定传输大文件。'
          : 'Wireless transfer is supported on Android. Keep both devices on the same Wi-Fi; disabling battery restrictions can improve large uploads on some devices.';
    }
    if (Platform.isMacOS) {
      return isChinese
          ? 'macOS 支持无线传书。若无法访问，请检查系统防火墙是否允许 Anx Reader 接收入站连接。'
          : 'Wireless transfer is supported on macOS. If the address is unreachable, check that the system firewall allows inbound connections for Anx Reader.';
    }
    if (Platform.isWindows || Platform.isLinux) {
      return isChinese
          ? '桌面端支持无线传书。若显示多个地址，优先使用 Wi-Fi 或以太网地址，避免选择 VPN/虚拟网卡地址。'
          : 'Wireless transfer is supported on desktop. If multiple addresses are shown, prefer Wi-Fi or Ethernet and avoid VPN or virtual adapter addresses.';
    }
    return isChinese
        ? '当前平台暂不支持 Web 端作为无线传书接收端。'
        : 'This platform cannot act as a wireless transfer receiver.';
  }
}

class _TransferAddress {
  const _TransferAddress({
    required this.address,
    required this.interfaceName,
  });

  final String address;
  final String interfaceName;
}

class _AddressTile extends StatelessWidget {
  const _AddressTile({
    required this.address,
    required this.interfaceName,
    required this.onCopy,
  });

  final String address;
  final String interfaceName;
  final VoidCallback onCopy;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onCopy,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color:
              theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.35),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    address,
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontFamily: 'monospace',
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    interfaceName,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.copy, size: 16, color: theme.colorScheme.primary),
          ],
        ),
      ),
    );
  }
}
