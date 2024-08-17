import 'dart:ui';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:walletconnect_flutter_v2/apis/web3app/web3app.dart';
import 'package:walletconnect_flutter_v2/walletconnect_flutter_v2.dart';
import 'package:walletconnect_flutter_v2_wallet/pages/apps_page.dart';
import 'package:web3modal_flutter/services/w3m_service/w3m_service.dart';
import 'package:web3modal_flutter/web3modal_flutter.dart';
import 'package:web3dart/web3dart.dart';
import 'package:http/http.dart';

class LaWalletScreen extends StatefulWidget {
  @override
  _LaWalletScreenState createState() => _LaWalletScreenState();
}

class _LaWalletScreenState extends State<LaWalletScreen>
    with TickerProviderStateMixin {
  late AnimationController _controller;
  late AnimationController _blurController;
  late Animation<double> _fadeInAnimation;
  late Animation<double> _blurAnimation;
  final myController = TextEditingController(text: 'your.email@example.com');
  // Magic magic = Magic.instance;
  late W3MService _w3mService;
  void _initializeW3MService() async {
    // Add your own custom chain to chains presets list to show when using W3MNetworkSelectButton
    // See https://docs.walletconnect.com/appkit/flutter/core/custom-chains
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
    try {
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
      await _w3mService.init();
      W3MChainPresets.chains.putIfAbsent('274', () => lachain);
      await _w3mService.selectChain(lachain);
      print('session');
      print('namespace');
      print(_w3mService.session?.namespaces);
      print('raw json');
      print(_w3mService.session?.toRawJson());
      print('address');
      print(_w3mService.session?.address);
      print('chainId');
      print(_w3mService.session?.chainId);
      var apiUrl =
          "https://rpc2.mainnet.lachain.network"; //Replace with your API

      var httpClient = Client();
      var ethClient = Web3Client(apiUrl, httpClient);
      print(_w3mService.isConnected);
      EtherAmount balance = await ethClient.getBalance(
          EthereumAddress.fromHex(_w3mService.session?.address ?? ''));
      print(balance.getValueInUnit(EtherUnit.ether));
      // if (_w3mService.isConnected) {
      //   Navigator.push(
      //       context, MaterialPageRoute(builder: (context) => AppsPage()));
      // }
      print(_w3mService.web3App?.authKeys.toString());
      _w3mService.web3App!.onSessionConnect.subscribe((event) {
        Navigator.push(
            context, MaterialPageRoute(builder: (context) => AppsPage()));
      });
      getWalletBalance();
      // _w3mService.addListener(() {
      //   Navigator.push(
      //       context, MaterialPageRoute(builder: (context) => AppsPage()));
      // });
      print('aaaa');
      print(_w3mService.selectedWallet);
    } catch (ex) {
      print('ERRORRRRRR');
      print(ex.toString());
    }
  }

  Future<void> getWalletBalance() async {
    // Get balance of wallet
    print('getWalletBalance');
    print('_w3mService.session?.address');
    print(_w3mService.session?.address);
  }

  @override
  void initState() {
    super.initState();
    _initializeW3MService();

    /// Checks if the user is already loggedIn
    // var future = magic.user.isLoggedIn();
    // future.then((isLoggedIn) {
    //   if (isLoggedIn) {
    //     /// Navigate to home page
    //     //   Navigator.push(context,
    //     //       MaterialPageRoute(builder: (context) => const HomePage()));
    //   }
    // });
    _controller = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );

    _blurController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );

    _fadeInAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeIn),
    );

    _blurAnimation = Tween<double>(begin: 5, end: 20).animate(
      CurvedAnimation(
        parent: _blurController,
        curve: Curves.easeInOut,
      ),
    );

    _controller.forward();
    _blurController.repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    _blurController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Image.asset(
            'assets/background.png',
            fit: BoxFit.cover,
            width: double.infinity,
            height: double.infinity,
          ),
          Container(
            color: Colors.black.withOpacity(0.5),
            width: double.infinity,
            height: double.infinity,
          ),
          FadeTransition(
            opacity: _fadeInAnimation,
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Image.asset(
                    'assets/lachain_logo.png',
                    width: 200,
                    fit: BoxFit.cover,
                  ),
                  SizedBox(height: 20),
                  Text(
                    'LaWallet',
                    style: TextStyle(
                      fontSize: 44,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 20),
                  Column(
                      children: !_w3mService.isConnected
                          ? [
                              W3MConnectWalletButton(
                                service: _w3mService,
                              ),
                            ]
                          : [
                              Container(
                                  decoration:
                                      BoxDecoration(color: Colors.white),
                                  child:
                                      W3MAccountButton(service: _w3mService)),
                            ]),
                  Visibility(
                    // visible: !_w3mService.isConnected,
                    visible: false,
                    child: Container(
                      width: 160,
                      child: W3MConnectWalletButton(
                          service: _w3mService,
                          context: context,
                          custom: AnimatedBuilder(
                            animation: _blurAnimation,
                            builder: (context, child) {
                              return Container(
                                // onPressed: null,
                                // onPressed: () {
                                //   // Add your connect wallet logic here
                                //   print('open modal view');
                                //   _w3mService.openModalView();
                                //   print(_w3mService.modalContext);
                                // },
                                // style: ElevatedButton.styleFrom(
                                //   padding: EdgeInsets.zero,
                                //   shape: RoundedRectangleBorder(
                                //     borderRadius: BorderRadius.circular(30),
                                //   ),
                                // ),
                                child: Container(
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      begin: Alignment.centerLeft,
                                      end: Alignment.centerRight,
                                      colors: [
                                        Color(0xFF7908FF),
                                        Color(0xFF8F13E6),
                                        Color(0xFFD1349C),
                                        Color(0xFFEC4280),
                                      ],
                                      stops: [0.0, 0.25, 0.86, 1.0],
                                    ),
                                    borderRadius: BorderRadius.circular(30),
                                    boxShadow: [
                                      BoxShadow(
                                        color:
                                            Color(0xFFEC4280).withOpacity(0.3),
                                        blurRadius: 10,
                                        offset: Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(30),
                                    child: BackdropFilter(
                                      filter: ImageFilter.blur(
                                        sigmaX: _blurAnimation.value,
                                        sigmaY: _blurAnimation.value,
                                        tileMode: TileMode.mirror,
                                      ),
                                      child: Container(
                                        constraints: BoxConstraints(
                                            minWidth: 200, minHeight: 50),
                                        alignment: Alignment.center,
                                        child: Text(
                                          'Connect Wallet',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 14,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            },
                          )),
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Web3ModalTheme(
          //   isDarkMode: true,
          //   child: MaterialApp(
          //     title: 'AppKit Demo',
          //     home: Builder(
          //       builder: (context) {
          //         return Scaffold(
          //           appBar: AppBar(
          //             title: const Text('AppKit Demo'),
          //             backgroundColor:
          //                 Web3ModalTheme.colorsOf(context).background100,
          //             foregroundColor:
          //                 Web3ModalTheme.colorsOf(context).foreground100,
          //           ),
          //           backgroundColor:
          //               Web3ModalTheme.colorsOf(context).background300,
          //           body: Container(
          //             constraints: const BoxConstraints.expand(),
          //             padding: const EdgeInsets.all(12.0),
          //             child: Column(
          //               children: ,
          //             ),
          //           ),
          //         );
          //       },
          //     ),
          //   ),
          // ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 80,
            child: FadeTransition(
              opacity: _fadeInAnimation,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: RichText(
                  textAlign: TextAlign.center,
                  text: TextSpan(
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                    ),
                    children: [
                      TextSpan(text: 'Ao continuar, aceito os '),
                      TextSpan(
                        text: 'Termos de Serviço',
                        style: TextStyle(
                          color: Colors.blue,
                          decoration: TextDecoration.underline,
                        ),
                        recognizer: TapGestureRecognizer()
                          ..onTap = () {
                            // Add logic to open Terms of Service
                          },
                      ),
                      TextSpan(text: ' e a '),
                      TextSpan(
                        text: 'Política de Privacidade',
                        style: TextStyle(
                          color: Colors.blue,
                          decoration: TextDecoration.underline,
                        ),
                        recognizer: TapGestureRecognizer()
                          ..onTap = () {
                            // Add logic to open Privacy Policy
                          },
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
