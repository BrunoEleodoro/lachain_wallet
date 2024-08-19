import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:fl_toast/fl_toast.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get_it/get_it.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:qr_bar_code_scanner_dialog/qr_bar_code_scanner_dialog.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:url_launcher/url_launcher_string.dart';
import 'package:walletconnect_flutter_v2_wallet/dependencies/bottom_sheet/i_bottom_sheet_service.dart';
import 'package:walletconnect_flutter_v2_wallet/dependencies/deep_link_handler.dart';
import 'package:walletconnect_flutter_v2_wallet/dependencies/i_web3wallet_service.dart';

import 'package:walletconnect_flutter_v2_wallet/models/chain_metadata.dart';
import 'package:walletconnect_flutter_v2_wallet/pages/app_detail_page.dart';
import 'package:walletconnect_flutter_v2_wallet/utils/constants.dart';
import 'package:walletconnect_flutter_v2_wallet/utils/crypto/chain_data.dart';
import 'package:walletconnect_flutter_v2_wallet/utils/crypto/eip155.dart';
import 'package:walletconnect_flutter_v2_wallet/utils/crypto/polkadot.dart';
import 'package:walletconnect_flutter_v2_wallet/utils/crypto/solana.dart';
import 'package:walletconnect_flutter_v2_wallet/utils/eth_utils.dart';
import 'package:walletconnect_flutter_v2_wallet/utils/string_constants.dart';
import 'package:walletconnect_flutter_v2_wallet/widgets/chain_button.dart';
import 'package:walletconnect_flutter_v2_wallet/imports.dart';
import 'package:walletconnect_flutter_v2_wallet/widgets/pairing_item.dart';
import 'package:walletconnect_flutter_v2_wallet/widgets/uri_input_popup.dart';
import 'package:walletconnect_modal_flutter/models/listings.dart';
import 'package:walletconnect_modal_flutter/walletconnect_modal_flutter.dart';

class ConnectPage extends StatefulWidget {
  const ConnectPage({
    super.key,
    required this.web3App,
  });

  final Web3App web3App;

  @override
  ConnectPageState createState() => ConnectPageState();
}

class ConnectPageState extends State<ConnectPage> {
  bool _testnetOnly = false;
  final List<ChainMetadata> _selectedChains = [];
  bool _shouldDismissQrCode = true;
  bool _initialized = false;
  late IWalletConnectModalService _walletConnectModalService;
  List<PairingInfo> _pairings = [];
  late IWeb3WalletService _web3walletService;
  late IWeb3Wallet _web3Wallet;
  @override
  void initState() {
    super.initState();
    _web3walletService = GetIt.I<IWeb3WalletService>();
    _web3Wallet = _web3walletService.web3wallet;
    _pairings = _web3Wallet.pairings.getAll();
    _pairings = _pairings.where((p) => p.active).toList();
    _registerListeners();
    // TODO web3Wallet.core.echo.register(firebaseAccessToken);
    DeepLinkHandler.onLink.listen(_onFoundUri);
    DeepLinkHandler.checkInitialLink();
    _initializeWCM();
  }

  void _refreshState(dynamic event) async {
    setState(() {});
  }

  void _registerListeners() {
    _web3Wallet.core.relayClient.onRelayClientMessage.subscribe(
      _onRelayClientMessage,
    );
    _web3Wallet.pairings.onSync.subscribe(_refreshState);
    _web3Wallet.pairings.onUpdate.subscribe(_refreshState);
    _web3Wallet.onSessionConnect.subscribe(_refreshState);
    _web3Wallet.onSessionDelete.subscribe(_refreshState);
  }

  void _unregisterListeners() {
    _web3Wallet.onSessionDelete.unsubscribe(_refreshState);
    _web3Wallet.onSessionConnect.unsubscribe(_refreshState);
    _web3Wallet.pairings.onSync.unsubscribe(_refreshState);
    _web3Wallet.pairings.onUpdate.unsubscribe(_refreshState);
    _web3Wallet.core.relayClient.onRelayClientMessage.unsubscribe(
      _onRelayClientMessage,
    );
  }

  Future<void> _initializeWCM() async {
    _walletConnectModalService = WalletConnectModalService(
      web3App: widget.web3App,
    );

    await _walletConnectModalService.init();

    setState(() => _initialized = true);
    // _walletConnectModalService.open(context: context);
    _walletConnectModalService.clearPreviousInactivePairings();
    _walletConnectModalService.launchCurrentWallet();
    _walletConnectModalService.open(context: context);
    // var connectResponse = await widget.web3App.connect(
    //   requiredNamespaces: requiredNamespaces,
    //   optionalNamespaces: optionalNamespaces,
    // );
    // print(connectResponse);
    print('OPENED');
    print(_walletConnectModalService.wcUri);
    print('URI');
    widget.web3App.onSessionConnect.subscribe(_onSessionConnect);
    print('SUBSCRIBED');
    await _walletConnectModalService.rebuildConnectionUri();

    Future.delayed(const Duration(seconds: 5), () async {
      print(_walletConnectModalService.wcUri);

      var res = await GetIt.I<IWeb3WalletService>()
          .web3wallet
          .pair(uri: Uri.parse(_walletConnectModalService.wcUri!));

      // await GetIt.I<IWeb3WalletService>().web3wallet.pair(
      //       uri: Uri.parse(
      //           'wc:8ffe145d40ba2a4043246ebda4576b39370d1559c7823bf14f9a03dac7204c8a@2?relay-protocol=irn&symKey=76240e47da3444966f963abf64aac1f66cca29468d9237115a81983cf51c9dcb'),
      //     );
      print(res);
      print('PAIRED');
      var pair =
          GetIt.I<IWeb3WalletService>().web3wallet.pairings.getAll().last;
      GetIt.I<IWeb3WalletService>()
          .web3wallet
          .core
          .pairing
          .activate(topic: pair.topic);
      GetIt.I<IWeb3WalletService>()
          .web3wallet
          .onSessionProposal
          .subscribe((session) {
        print('SESSION PROPOSAL');
        print(session);
      });
      // GetIt.I<IWeb3WalletService>().web3wallet.respondSessionRequest(
      //     topic: _walletConnectModalService.session!.topic,
      //     response: JsonRpcResponse(
      //       id: 1,
      //       result: 'success',
      //     ));
    });
  }

  @override
  void dispose() {
    widget.web3App.onSessionConnect.unsubscribe(_onSessionConnect);
    _unregisterListeners();
    super.dispose();
  }

  void _onRelayClientMessage(MessageEvent? event) async {
    _refreshState(event);
    if (event != null) {
      final jsonObject = await EthUtils.decodeMessageEvent(event);
      if (!mounted) return;
      if (jsonObject is JsonRpcRequest &&
          jsonObject.method == 'wc_sessionPing') {
        showPlatformToast(
          duration: const Duration(seconds: 1),
          child: Container(
            padding: const EdgeInsets.all(StyleConstants.linear8),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(
                StyleConstants.linear16,
              ),
            ),
            child: Text(jsonObject.method, maxLines: 1),
          ),
          context: context,
        );
      }
    }
  }

  Widget _buildNoPairingMessage() {
    return const Center(
      child: Text(
        StringConstants.noApps,
        textAlign: TextAlign.center,
        style: StyleConstants.bodyText,
      ),
    );
  }

  void _onListItemTap(PairingInfo pairing) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AppDetailPage(
          pairing: pairing,
        ),
      ),
    );
  }

  Widget _buildPairingList() {
    final pairingItems = _pairings
        .map(
          (PairingInfo pairing) => PairingItem(
            key: ValueKey(pairing.topic),
            pairing: pairing,
            onTap: () => _onListItemTap(pairing),
          ),
        )
        .toList();

    return ListView.builder(
      itemCount: pairingItems.length,
      itemBuilder: (BuildContext context, int index) {
        return pairingItems[index];
      },
    );
  }

  Future<dynamic> _onCopyQrCode() async {
    final uri = await GetIt.I<IBottomSheetService>().queueBottomSheet(
      widget: UriInputPopup(),
    );
    if (uri is String) {
      _onFoundUri(uri);
    }
  }

  Future _onScanQrCode() async {
    try {
      QrBarCodeScannerDialog().getScannedQrBarCode(
        context: context,
        onCode: (value) {
          if (!mounted) return;
          _onFoundUri(value);
        },
      );
    } catch (e) {
      debugPrint(e.toString());
    }
  }

  Future<void> _onFoundUri(String? uri) async {
    if ((uri ?? '').isEmpty) return;
    try {
      DeepLinkHandler.waiting.value = true;
      final Uri uriData = Uri.parse(uri!);
      await _web3Wallet.pair(uri: uriData);
    } on WalletConnectError catch (e) {
      _showErrorDialog('${e.code}: ${e.message}');
    } on TimeoutException catch (_) {
      _showErrorDialog('Time out error. Check your connection.');
    }
  }

  void _showErrorDialog(String message) {
    DeepLinkHandler.waiting.value = false;
    showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text(
              'Error',
              style: TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.bold,
              ),
            ),
            content: Text(
              message,
              style: const TextStyle(
                color: Colors.black,
              ),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: const Text(
                  'Close',
                  style: TextStyle(
                    color: Colors.black,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              )
            ],
          );
        });
  }

  void setTestnet(bool value) {
    if (value != _testnetOnly) {
      _selectedChains.clear();
    }
    _testnetOnly = value;
  }

  void _selectChain(ChainMetadata chain) {
    setState(() {
      if (_selectedChains.contains(chain)) {
        _selectedChains.remove(chain);
      } else {
        _selectedChains.add(chain);
      }
      _updateNamespaces();
    });
  }

  Map<String, RequiredNamespace> requiredNamespaces = {};
  Map<String, RequiredNamespace> optionalNamespaces = {};

  void _updateNamespaces() {
    optionalNamespaces = {};

    final evmChains =
        _selectedChains.where((e) => e.type == ChainType.eip155).toList();
    if (evmChains.isNotEmpty) {
      optionalNamespaces['eip155'] = RequiredNamespace(
        chains: evmChains.map((c) => c.chainId).toList(),
        methods: EIP155.methods.values.toList(),
        events: EIP155.events.values.toList(),
      );
    }

    final solanaChains =
        _selectedChains.where((e) => e.type == ChainType.solana).toList();
    if (solanaChains.isNotEmpty) {
      optionalNamespaces['solana'] = RequiredNamespace(
        chains: solanaChains.map((c) => c.chainId).toList(),
        methods: Solana.methods.values.toList(),
        events: Solana.events.values.toList(),
      );
    }

    final polkadotChains =
        _selectedChains.where((e) => e.type == ChainType.polkadot).toList();
    if (polkadotChains.isNotEmpty) {
      optionalNamespaces['polkadot'] = RequiredNamespace(
        chains: polkadotChains.map((c) => c.chainId).toList(),
        methods: Polkadot.methods.values.toList(),
        events: Polkadot.events.values.toList(),
      );
    }

    if (optionalNamespaces.isEmpty) {
      requiredNamespaces = {};
    } else {
      // WalletConnectModal still requires to have requiredNamespaces
      // this has to be changed in that SDK
      requiredNamespaces = {
        'eip155': const RequiredNamespace(
          chains: ['eip155:1'],
          methods: ['personal_sign', 'eth_signTransaction'],
          events: ['chainChanged'],
        ),
      };
    }

    _walletConnectModalService.setRequiredNamespaces(
      requiredNamespaces: requiredNamespaces,
    );
    debugPrint(
        '[SampleDapp] requiredNamespaces ${jsonEncode(requiredNamespaces)}');
    _walletConnectModalService.setOptionalNamespaces(
      optionalNamespaces: optionalNamespaces,
    );
    debugPrint(
        '[SampleDapp] optionalNamespaces ${jsonEncode(optionalNamespaces)}');
    Future.delayed(const Duration(seconds: 5), () async {
      // final Uri uriData = Uri.parse(_walletConnectModalService.wcUri!);
      // GetIt.I<IWeb3WalletService>().web3wallet.pair(uri: uriData).then((res) {
      //   print('PAIRING TOPIC 222: ${res.topic}');
      //   print(res);

      // }).catchError((e) {
      //   print('ERROR: $e');
      // });

      // await _walletConnectModalService.session.future.then((session) {
      //   print(session);
      //   print('SADASD');
      //   GetIt.I<IWeb3WalletService>().web3wallet.emitSessionEvent(
      //         topic: session.pairingTopic,
      //         event: const SessionEventParams(
      //             name: 'eth_sendTransaction',
      //             data: ['0x0000000000000000000000000000000000000000']),
      //         chainId: 'eip155:274',
      //       );
      // });
    });
  }

  @override
  Widget build(BuildContext context) {
    // Build the list of chain buttons, clear if the textnet changed
    final testChains = ChainData.allChains.where((e) => e.isTestnet).toList();
    final mainChains = ChainData.allChains.where((e) => !e.isTestnet).toList();
    final List<ChainMetadata> chains = _testnetOnly ? testChains : mainChains;

    final List<Widget> evmChainButtons = [];
    final List<Widget> nonEvmChainButtons = [];

    final evmChains = chains.where((e) => e.type == ChainType.eip155);
    final nonEvmChains = chains.where((e) => e.type != ChainType.eip155);

    for (final ChainMetadata chain in evmChains) {
      // Build the button
      evmChainButtons.add(
        ChainButton(
          chain: chain,
          onPressed: () => _selectChain(chain),
          selected: _selectedChains.contains(chain),
        ),
      );
    }

    for (final ChainMetadata chain in nonEvmChains) {
      // Build the button
      nonEvmChainButtons.add(
        ChainButton(
          chain: chain,
          onPressed: () => _selectChain(chain),
          selected: _selectedChains.contains(chain),
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: StyleConstants.linear8),
      children: <Widget>[
        Column(
          children: [
            const Text(
              'Flutter Dapp',
              style: StyleConstants.subtitleText,
              textAlign: TextAlign.center,
            ),
            FutureBuilder<PackageInfo>(
              future: PackageInfo.fromPlatform(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const SizedBox.shrink();
                }
                final v = snapshot.data!.version;
                final b = snapshot.data!.buildNumber;
                const f = String.fromEnvironment('FLUTTER_APP_FLAVOR');
                return Text('$v-$f ($b) - SDK v$packageVersion');
              },
            ),
          ],
        ),
        SizedBox(
          height: StyleConstants.linear48,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                StringConstants.testnetsOnly,
                style: StyleConstants.buttonText,
              ),
              Switch(
                value: _testnetOnly,
                onChanged: (value) {
                  setState(() {
                    _selectedChains.clear();
                    _testnetOnly = value;
                  });
                },
              ),
            ],
          ),
        ),
        const Text('EVM Chains:', style: StyleConstants.buttonText),
        const SizedBox(height: StyleConstants.linear8),
        Wrap(
          spacing: 10.0,
          children: evmChainButtons,
        ),
        const Divider(),
        const Text('Non EVM Chains:', style: StyleConstants.buttonText),
        Wrap(
          spacing: 10.0,
          children: nonEvmChainButtons,
        ),
        const Divider(),
        if (_initialized)
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: StyleConstants.linear8),
              const Text(
                'Use WalletConnectModal:',
                style: StyleConstants.buttonText,
              ),
              const SizedBox(height: StyleConstants.linear8),
              WalletConnectModalConnect(
                service: _walletConnectModalService,
                width: double.infinity,
                height: 50.0,
              ),
            ],
          ),
        const SizedBox(height: StyleConstants.linear8),
        const Divider(),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: StyleConstants.linear8),
            const Text(
              'Use custom connection:',
              style: StyleConstants.buttonText,
            ),
            const SizedBox(height: StyleConstants.linear8),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: _buttonStyle,
                onPressed: _selectedChains.isEmpty
                    ? null
                    : () => _onConnect(
                          showToast: (m) async {
                            await showPlatformToast(
                                child: Text(m), context: context);
                          },
                          closeModal: () {
                            if (Navigator.canPop(context)) {
                              Navigator.of(context).pop();
                            }
                          },
                        ),
                child: const Text(
                  StringConstants.connect,
                  style: StyleConstants.buttonText,
                ),
              ),
            ),
            const SizedBox(height: StyleConstants.linear8),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: _buttonStyle,
                onPressed: _selectedChains.isEmpty
                    ? null
                    : () => _oneClickAuth(
                          closeModal: () {
                            if (Navigator.canPop(context)) {
                              Navigator.of(context).pop();
                            }
                          },
                          showToast: (message) {
                            showPlatformToast(
                                child: Text(message), context: context);
                          },
                        ),
                child: const Text(
                  'One-Click Auth',
                  style: StyleConstants.buttonText,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: StyleConstants.linear16),
      ],
    );
  }

  // Future<void> _onConnectWeb() async {
  //   // `Ethereum.isSupported` is the same as `ethereum != null`
  //   if (ethereum != null) {
  //     try {
  //       // Prompt user to connect to the provider, i.e. confirm the connection modal
  //       final accounts = await ethereum!.requestAccount();
  //       // Get all accounts in node disposal
  //       debugPrint('accounts ${accounts.join(', ')}');
  //     } on EthereumUserRejected {
  //       debugPrint('User rejected the modal');
  //     }
  //   }
  // }

  Future<void> _onConnect({
    Function(String message)? showToast,
    VoidCallback? closeModal,
  }) async {
    debugPrint('[SampleDapp] Creating connection and session');
    // It is currently safer to send chains approvals on optionalNamespaces
    // but depending on Wallet implementation you may need to send some (for innstance eip155:1) as required
    final connectResponse = await widget.web3App.connect(
      requiredNamespaces: requiredNamespaces,
      optionalNamespaces: optionalNamespaces,
    );

    final encodedUri = Uri.encodeComponent(connectResponse.uri.toString());
    String flavor = '-${const String.fromEnvironment('FLUTTER_APP_FLAVOR')}';
    flavor = flavor.replaceAll('-production', '');
    final uri = 'wcflutterwallet$flavor://wc?uri=$encodedUri';
    if (await canLaunchUrlString(uri)) {
      final openApp = await showDialog(
        // ignore: use_build_context_synchronously
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            content: const Text('Do you want to open with Flutter Wallet'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Show QR'),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('Open'),
              ),
            ],
          );
        },
      );
      if (openApp) {
        launchUrlString(uri, mode: LaunchMode.externalApplication);
      } else {
        _showQrCode(connectResponse.uri.toString());
      }
    } else {
      _showQrCode(connectResponse.uri.toString());
    }

    debugPrint('[SampleDapp] Awaiting session proposal settlement');
    final _ = await connectResponse.session.future;

    showToast?.call(StringConstants.connectionEstablished);
    closeModal?.call();
  }

  Future<void> _showQrCode(String uri) async {
    // Show the QR code
    debugPrint('[SampleDapp] Showing QR Code: $uri');
    _shouldDismissQrCode = true;
    if (kIsWeb) {
      await showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return AlertDialog(
            insetPadding: const EdgeInsets.all(0.0),
            contentPadding: const EdgeInsets.all(0.0),
            backgroundColor: Colors.white,
            content: SizedBox(
              width: 400.0,
              child: AspectRatio(
                aspectRatio: 0.8,
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: _QRCodeView(
                    uri: uri,
                  ),
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              )
            ],
          );
        },
      );
      _shouldDismissQrCode = false;
      return;
    }
    Navigator.push(
      context,
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (context) => QRCodeScreen(uri: uri),
      ),
    );
  }

  void _requestAuth(
    SessionConnect? event, {
    Function(String message)? showToast,
  }) async {
    final shouldAuth = await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          insetPadding: const EdgeInsets.all(0.0),
          contentPadding: const EdgeInsets.all(0.0),
          backgroundColor: Colors.white,
          title: const Text('Request Auth?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context, true);
              },
              child: const Text('Yes!'),
            ),
          ],
        );
      },
    );
    if (shouldAuth != true) return;

    try {
      final pairingTopic = event?.session.pairingTopic;
      // Send off an auth request now that the pairing/session is established
      final authResponse = await widget.web3App.requestAuth(
        pairingTopic: pairingTopic,
        params: AuthRequestParams(
          chainId: 'eip155:1',
          domain: Constants.domain,
          aud: Constants.aud,
          statement: 'Welcome to example flutter app',
        ),
      );

      final scheme = event?.session.peer.metadata.redirect?.native;
      String flavor = '-${const String.fromEnvironment('FLUTTER_APP_FLAVOR')}';
      flavor = flavor.replaceAll('-production', '');
      launchUrlString(
        scheme ?? 'wcflutterwallet$flavor://',
        mode: LaunchMode.externalApplication,
      );

      debugPrint('[SampleDapp] Awaiting authentication response');
      final response = await authResponse.completer.future;
      if (response.result != null) {
        showToast?.call(StringConstants.authSucceeded);
      } else {
        final error = response.error ?? response.jsonRpcError;
        showToast?.call(error.toString());
      }
    } catch (e) {
      debugPrint('[SampleDapp] auth $e');
      showToast?.call(StringConstants.connectionFailed);
    }
  }

  void _oneClickAuth({
    VoidCallback? closeModal,
    Function(String message)? showToast,
  }) async {
    final methods1 = requiredNamespaces['eip155']?.methods ?? [];
    final methods2 = optionalNamespaces['eip155']?.methods ?? [];
    String flavor = '-${const String.fromEnvironment('FLUTTER_APP_FLAVOR')}';
    flavor = flavor.replaceAll('-production', '');
    final authResponse = await widget.web3App.authenticate(
      params: SessionAuthRequestParams(
        chains: _selectedChains.map((e) => e.chainId).toList(),
        domain: 'wcflutterdapp$flavor://',
        nonce: AuthUtils.generateNonce(),
        uri: Constants.aud,
        statement: 'Welcome to example flutter app',
        methods: <String>{...methods1, ...methods2}.toList(),
      ),
    );

    final encodedUri = Uri.encodeComponent(authResponse.uri.toString());
    final uri = 'wcflutterwallet$flavor://wc?uri=$encodedUri';

    if (await canLaunchUrlString(uri)) {
      final openApp = await showDialog(
        // ignore: use_build_context_synchronously
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            content: const Text('Do you want to open with Flutter Wallet'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Show QR'),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('Open'),
              ),
            ],
          );
        },
      );
      if (openApp) {
        launchUrlString(uri, mode: LaunchMode.externalApplication);
      } else {
        _showQrCode(authResponse.uri.toString());
      }
    } else {
      _showQrCode(authResponse.uri.toString());
    }

    try {
      debugPrint('[SampleDapp] Awaiting 1-CA session');
      final response = await authResponse.completer.future;

      if (response.session != null) {
        showToast?.call(
          '${StringConstants.authSucceeded} and ${StringConstants.connectionEstablished}',
        );
      } else {
        final error = response.error ?? response.jsonRpcError;
        showToast?.call(error.toString());
      }
    } catch (e) {
      debugPrint('[SampleDapp] 1-CA $e');
      showToast?.call(StringConstants.connectionFailed);
    }
    closeModal?.call();
  }

  void _onSessionConnect(SessionConnect? event) async {
    if (event == null) return;

    setState(() {
      _selectedChains.clear();
    });

    if (_shouldDismissQrCode && Navigator.canPop(context)) {
      _shouldDismissQrCode = false;
      Navigator.pop(context);
    }

    _requestAuth(
      event,
      showToast: (message) {
        showPlatformToast(child: Text(message), context: context);
      },
    );
  }

  ButtonStyle get _buttonStyle => ButtonStyle(
        backgroundColor: MaterialStateProperty.resolveWith<Color>(
          (states) {
            if (states.contains(MaterialState.disabled)) {
              return StyleConstants.grayColor;
            }
            return StyleConstants.primaryColor;
          },
        ),
        minimumSize: MaterialStateProperty.all<Size>(const Size(
          1000.0,
          StyleConstants.linear48,
        )),
        shape: MaterialStateProperty.all<RoundedRectangleBorder>(
          RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(
              StyleConstants.linear8,
            ),
          ),
        ),
      );
}

class QRCodeScreen extends StatefulWidget {
  const QRCodeScreen({super.key, required this.uri});
  final String uri;

  @override
  State<QRCodeScreen> createState() => _QRCodeScreenState();
}

class _QRCodeScreenState extends State<QRCodeScreen> {
  @override
  Widget build(BuildContext context) {
    return Material(
      child: Scaffold(
        appBar: AppBar(title: const Text(StringConstants.scanQrCode)),
        body: _QRCodeView(
          uri: widget.uri,
        ),
      ),
    );
  }
}

class _QRCodeView extends StatelessWidget {
  const _QRCodeView({required this.uri});
  final String uri;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        QrImageView(data: uri),
        const SizedBox(
          height: StyleConstants.linear16,
        ),
        ElevatedButton(
          onPressed: () {
            Clipboard.setData(
              ClipboardData(text: uri.toString()),
            ).then(
              (_) => showPlatformToast(
                child: const Text(StringConstants.copiedToClipboard),
                context: context,
              ),
            );
          },
          child: const Text('Copy URL to Clipboard'),
        ),
      ],
    );
  }
}
