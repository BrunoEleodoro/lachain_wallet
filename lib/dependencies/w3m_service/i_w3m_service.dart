import 'dart:ui';

import 'package:walletconnect_flutter_v2/walletconnect_flutter_v2.dart';
import 'package:web3modal_flutter/web3modal_flutter.dart';
import 'package:web3dart/web3dart.dart';

abstract class IW3mService {
  late W3MService w3mService;

  Future<void> initializeW3MService();

  Future<void> init();

  Future<void> selectChain(W3MChainInfo chain);

  bool get isConnected;

  Web3App? get web3App;

  W3MSession? get session;

  W3MWalletInfo? get selectedWallet;

  Future<EtherAmount> getWalletBalance();

  void addListener(VoidCallback listener);
}
