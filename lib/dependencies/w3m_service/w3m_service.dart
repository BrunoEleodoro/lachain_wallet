import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:http/http.dart';
import 'package:walletconnect_flutter_v2/apis/web3app/web3app.dart';
import 'package:walletconnect_flutter_v2_wallet/dependencies/w3m_service/i_w3m_service.dart';
import 'package:web3dart/web3dart.dart';
import 'package:web3modal_flutter/web3modal_flutter.dart';

class W3mService extends IW3mService {
  late W3MService _w3mService;

  @override
  Future<void> initializeW3MService() async {
    Map<String, W3MNamespace> lachainNamespace = {
      '274': const W3MNamespace(
        chains: ['274'],
        methods: [
          'eth_sendTransaction',
          'eth_signTransaction',
          'eth_sign',
          'eth_signTypedData',
          'personal_sign',
          'eth_getBalance',
          'eth_getTransactionCount',
          'eth_getBlockByNumber',
        ],
        events: ['accountsChanged', 'chainChanged', 'disconnect'],
      ),
    };

    _w3mService = W3MService(
      projectId: '3bd2c24308cacc6a68925788160c7409',
      enableEmail: true,
      enableAnalytics: true,
      requiredNamespaces: lachainNamespace,
      optionalNamespaces: lachainNamespace,
      metadata: const PairingMetadata(
        name: 'LaWallet',
        description: 'LaWallet',
        url: 'https://rpc2.mainnet.lachain.network',
        icons: [
          'https://docs.walletconnect.com/assets/images/web3modalLogo-2cee77e07851ba0a710b56d03d4d09dd.png'
        ],
        redirect: Redirect(
          native: 'web3modalflutter://',
          universal: 'https://walletconnect.com/appkit',
        ),
      ),
    );
  }

  @override
  void addListener(VoidCallback listener) {
    _w3mService.addListener(listener);
  }

  @override
  Future<EtherAmount> getWalletBalance() async {
    var apiUrl = "https://rpc2.mainnet.lachain.network";
    var httpClient = Client();
    var ethClient = Web3Client(apiUrl, httpClient);
    return await ethClient.getBalance(
        EthereumAddress.fromHex(_w3mService.session?.address ?? ''));
  }

  @override
  Future<void> init() async {
    await _w3mService.init();
    W3MChainInfo lachain = W3MChainInfo(
      chainId: '274',
      chainName: 'LaChain',
      namespace: '274',
      rpcUrl: 'https://rpc2.mainnet.lachain.network',
      tokenName: 'LAC',
      blockExplorer: W3MBlockExplorer(
        name: 'LaChain Explorer',
        url: 'https://explorer.lachain.network/tx',
      ),
      chainIcon: 'https://icons.duckduckgo.com/ip3/lachain.network.ico',
    );
    W3MChainPresets.chains.putIfAbsent('274', () => lachain);
    await selectChain(lachain);
  }

  @override
  bool get isConnected => _w3mService.isConnected;

  @override
  Future<void> selectChain(W3MChainInfo chain) async {
    await _w3mService.selectChain(chain);
  }

  @override
  W3MWalletInfo? get selectedWallet => _w3mService.selectedWallet;

  @override
  W3MSession? get session => _w3mService.session;

  @override
  Web3App? get web3App => _w3mService.web3App as Web3App?;
}
