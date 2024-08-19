import 'dart:async';

import 'package:fl_toast/fl_toast.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get_it/get_it.dart';
import 'package:get_it_mixin/get_it_mixin.dart';
import 'package:pretty_qr_code/pretty_qr_code.dart';
import 'package:qr_bar_code_scanner_dialog/qr_bar_code_scanner_dialog.dart';
import 'package:walletconnect_flutter_v2/walletconnect_flutter_v2.dart';
import 'package:walletconnect_flutter_v2_wallet/dependencies/bottom_sheet/i_bottom_sheet_service.dart';
import 'package:walletconnect_flutter_v2_wallet/dependencies/deep_link_handler.dart';
import 'package:walletconnect_flutter_v2_wallet/dependencies/i_web3wallet_service.dart';
import 'package:walletconnect_flutter_v2_wallet/dependencies/w3m_service/i_w3m_service.dart';
import 'package:walletconnect_flutter_v2_wallet/pages/app_detail_page.dart';
import 'package:walletconnect_flutter_v2_wallet/pages/swap_tokens_page.dart';
import 'package:walletconnect_flutter_v2_wallet/utils/constants.dart';
import 'package:walletconnect_flutter_v2_wallet/utils/eth_utils.dart';
import 'package:walletconnect_flutter_v2_wallet/utils/string_constants.dart';
import 'package:walletconnect_flutter_v2_wallet/widgets/pairing_item.dart';
import 'package:walletconnect_flutter_v2_wallet/widgets/uri_input_popup.dart';
import 'package:web3modal_flutter/services/w3m_service/w3m_service.dart';
import 'package:web3modal_flutter/web3modal_flutter.dart';

class AppsPage extends StatefulWidget with GetItStatefulWidgetMixin {
  AppsPage({Key? key}) : super(key: key);

  @override
  AppsPageState createState() => AppsPageState();
}

class AppsPageState extends State<AppsPage> with GetItStateMixin {
  List<PairingInfo> _pairings = [];
  late IWeb3WalletService _web3walletService;
  late IWeb3Wallet _web3Wallet;
  late W3MService _w3mService;
  late QrImage qrImage;

  @override
  void initState() {
    super.initState();

    final qrCode = QrCode(
      8,
      QrErrorCorrectLevel.H,
    )..addData(GetIt.I<IW3mService>().session?.address ?? '');

    qrImage = QrImage(qrCode);

    _web3walletService = GetIt.I<IWeb3WalletService>();
    _web3Wallet = _web3walletService.web3wallet;
    _pairings = _web3Wallet.pairings.getAll();
    _pairings = _pairings.where((p) => p.active).toList();
    //
    _registerListeners();
    // TODO web3Wallet.core.echo.register(firebaseAccessToken);
    DeepLinkHandler.onLink.listen(_onFoundUri);
    DeepLinkHandler.checkInitialLink();
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

  @override
  void dispose() {
    _unregisterListeners();
    super.dispose();
  }

  void _refreshState(dynamic event) async {
    setState(() {});
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

  String formatAddress(String address) {
    if (address.length < 10) return address;
    return address.substring(0, 6) +
        '...' +
        address.substring(address.length - 4);
  }

  @override
  Widget build(BuildContext context) {
    _pairings = _web3Wallet.pairings.getAll();
    _pairings = _pairings.where((p) => p.active).toList();
    var address = GetIt.I<IW3mService>().session?.address ?? '';
    var formattedAddress = formatAddress(address);

    return SafeArea(
      child: Scaffold(
        body: SingleChildScrollView(
          child: Stack(
            children: [
              // _pairings.isEmpty ? _buildNoPairingMessage() : _buildPairingList(),
              // Positioned(
              //   bottom: StyleConstants.magic20,
              //   right: StyleConstants.magic20,
              //   left: StyleConstants.magic20,
              //   child: Row(
              //     children: [
              //       const SizedBox(width: StyleConstants.magic20),
              //       _buildIconButton(Icons.copy, _onCopyQrCode),
              //       // const SizedBox(width: StyleConstants.magic20),
              //       // ,
              //     ],
              //   ),
              // ),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Olá, Bruno Eleodoro',
                          style: TextStyle(
                              fontSize: 24, fontWeight: FontWeight.bold),
                        ),
                        Icon(Icons.menu),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.purple.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.account_balance_wallet,
                              color: Colors.purple),
                          SizedBox(width: 8),
                          Text(formattedAddress),
                          Icon(Icons.arrow_drop_down, color: Colors.purple),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    FutureBuilder(
                      future: GetIt.I<IW3mService>().getWalletBalance(),
                      builder: (context, snapshot) {
                        return Text(
                          'LAC ${snapshot.data?.getInEther.toString()}',
                          style: TextStyle(
                              fontSize: 36, fontWeight: FontWeight.bold),
                        );
                      },
                    ),
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildActionButton(Icons.send, 'Enviar', () {
                          _onScanQrCodeSend();
                        }),
                        _buildActionButton(Icons.arrow_downward, 'Receber', () {
                          generateQrCode();
                        }),
                        _buildActionButton(Icons.refresh, 'Atividade', () {}),
                        _buildActionButton(Icons.qr_code_scanner, 'Conectar',
                            () {
                          _onScanQrCode();
                        }),
                      ],
                    ),
                    const SizedBox(height: 24),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.purple.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'ripio',
                            style: TextStyle(color: Colors.purple),
                          ),
                          Text(
                            'Adquira LAC agora mesmo!',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          Text(
                            'Pela Ripio você pode comprar o seu LAC e transferir na mesma hora para sua carteira.',
                            style: TextStyle(fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'Conheça outras aplicações:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 36),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildAppIcon(
                            Colors.blue,
                            'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcTwGTCh5mOfDPgsTKbfaWEJr8sYnvYRgeS6oQ&s',
                            'SambaSwap'),
                        _buildAppIcon(
                            Colors.green,
                            'https://taikai.azureedge.net/yuEPtUkCHI4OQo2ZvSu9Emv4Np3Ay0YNmucxKJ5qtig/rs:fit:350:0:0/aHR0cHM6Ly9zdG9yYWdlLmdvb2dsZWFwaXMuY29tL3RhaWthaS1zdG9yYWdlL2ltYWdlcy8xY2EwYzRmMC00Nzg3LTExZWYtYTUxZS01NzE3YWRjNjlmZTFpbWFnZSAyMy5wbmc',
                            'Caramel'),
                        _buildAppIcon(
                            Colors.orange,
                            'https://i.ibb.co/dQ5BZ0w/Screenshot-2024-08-13-at-18-20-33.png',
                            'CapyFi'),
                      ],
                    ),
                  ],
                ),
              ),
              ValueListenableBuilder(
                valueListenable: DeepLinkHandler.waiting,
                builder: (context, value, _) {
                  return Visibility(
                    visible: value,
                    child: Center(
                      child: Container(
                        decoration: const BoxDecoration(
                          color: Colors.black38,
                          borderRadius: BorderRadius.all(Radius.circular(50.0)),
                        ),
                        padding: const EdgeInsets.all(12.0),
                        child: const CircularProgressIndicator(
                          color: Colors.white,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () {},
          child: _buildIconButton(Icons.edit, _onCopyQrCode),
          // rounded
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(50.0),
          ),
        ),
      ),
    );
  }

  Widget _buildActionButton(
      IconData icon, String label, void Function()? onPressed) {
    return GestureDetector(
      onTap: onPressed,
      child: Column(
        children: [
          Container(
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.purple.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: Colors.purple),
          ),
          SizedBox(height: 4),
          Text(label, style: TextStyle(fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildAppIcon(Color color, String imageUrl, String appName) {
    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(_createRoute());
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 70,
            height: 70,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
            child: ClipOval(
              child: Image.network(
                imageUrl,
                fit: BoxFit.cover,
                width: double.infinity,
                height: double.infinity,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            appName,
            style: const TextStyle(fontSize: 12),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Route _createRoute() {
    return PageRouteBuilder(
      pageBuilder: (context, animation, secondaryAnimation) => SwapTokensPage(),
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        const begin = Offset(0.0, 1.0);
        const end = Offset.zero;
        const curve = Curves.ease;

        var tween =
            Tween(begin: begin, end: end).chain(CurveTween(curve: curve));

        return SlideTransition(
          position: animation.drive(tween),
          child: child,
        );
      },
    );
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

  Widget _buildIconButton(IconData icon, void Function()? onPressed) {
    return IconButton(
      icon: Icon(
        icon,
        color: StyleConstants.titleTextColor,
      ),
      iconSize: StyleConstants.linear24,
      onPressed: onPressed,
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

  Future generateQrCode() async {
    showDialog(
      useSafeArea: true,
      context: context,
      barrierDismissible: true,
      builder: (context) => Container(
        padding: EdgeInsets.all(16),
        width: double.infinity,
        height: 300,
        color: Colors.white,
        child: Column(
          children: [
            PrettyQrView(
              qrImage: qrImage,
            ),
            ElevatedButton(
                onPressed: () {
                  Clipboard.setData(ClipboardData(
                      text: GetIt.I<IW3mService>().session?.address ?? ''));
                },
                child: Text('Copy')),
            SizedBox(height: 16),
            // close modal
            ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: Text('Close'))
          ],
        ),
      ),
    );
  }

  Future _onScanQrCodeSend() async {
    try {
      QrBarCodeScannerDialog().getScannedQrBarCode(
        context: context,
        onCode: (value) {
          if (!mounted) return;
        },
      );
    } catch (e) {
      debugPrint(e.toString());
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
      debugPrint('AAAA uriData: ${uriData.toString()}');
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
}
