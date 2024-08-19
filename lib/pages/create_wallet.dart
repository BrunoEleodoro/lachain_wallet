import 'dart:ui';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:walletconnect_flutter_v2/apis/web3app/web3app.dart';
import 'package:walletconnect_flutter_v2/walletconnect_flutter_v2.dart';
import 'package:walletconnect_flutter_v2_wallet/pages/apps_page.dart';
import 'package:walletconnect_flutter_v2_wallet/dependencies/w3m_service/i_w3m_service.dart';
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

  @override
  void initState() {
    super.initState();
    GetIt.I<IW3mService>().init();
    GetIt.I<IW3mService>().w3mService.onModalConnect.subscribe((event) {
      print('ModalConnect event: $event');
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => AppsPage()),
      );
    });

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
                      children: !GetIt.I<IW3mService>().isConnected
                          ? [
                              W3MConnectWalletButton(
                                service: GetIt.I<IW3mService>().w3mService,
                              ),
                            ]
                          : [
                              Container(
                                  decoration:
                                      BoxDecoration(color: Colors.white),
                                  child: W3MAccountButton(
                                      service:
                                          GetIt.I<IW3mService>().w3mService)),
                            ]),
                  Visibility(
                    visible: false,
                    child: Container(
                      width: 160,
                      child: W3MConnectWalletButton(
                          service: GetIt.I<IW3mService>().w3mService,
                          context: context,
                          custom: AnimatedBuilder(
                            animation: _blurAnimation,
                            builder: (context, child) {
                              return Container(
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
          Positioned(
            left: 0,
            right: 0,
            bottom: 50,
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
