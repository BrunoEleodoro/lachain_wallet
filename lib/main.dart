import 'dart:convert';
import 'dart:developer';

import 'package:get_it/get_it.dart';
import 'package:get_it_mixin/get_it_mixin.dart';
import 'package:walletconnect_flutter_v2_wallet/dependencies/bottom_sheet/bottom_sheet_listener.dart';
import 'package:walletconnect_flutter_v2_wallet/dependencies/bottom_sheet/bottom_sheet_service.dart';
import 'package:walletconnect_flutter_v2_wallet/dependencies/bottom_sheet/i_bottom_sheet_service.dart';
import 'package:walletconnect_flutter_v2_wallet/dependencies/chains/cosmos_service.dart';
import 'package:walletconnect_flutter_v2_wallet/dependencies/chains/evm_service.dart';
import 'package:walletconnect_flutter_v2_wallet/dependencies/chains/kadena_service.dart';
import 'package:walletconnect_flutter_v2_wallet/dependencies/chains/polkadot_service.dart';
import 'package:walletconnect_flutter_v2_wallet/dependencies/chains/solana_service.dart';
import 'package:walletconnect_flutter_v2_wallet/dependencies/deep_link_handler.dart';
import 'package:walletconnect_flutter_v2_wallet/dependencies/i_web3wallet_service.dart';
import 'package:walletconnect_flutter_v2_wallet/dependencies/key_service/i_key_service.dart';
import 'package:walletconnect_flutter_v2_wallet/dependencies/key_service/key_service.dart';
import 'package:walletconnect_flutter_v2_wallet/dependencies/w3m_service/i_w3m_service.dart';
import 'package:walletconnect_flutter_v2_wallet/dependencies/w3m_service/w3m_service.dart';
import 'package:walletconnect_flutter_v2_wallet/dependencies/web3wallet_service.dart';
import 'package:walletconnect_flutter_v2_wallet/models/chain_data.dart';
import 'package:walletconnect_flutter_v2_wallet/models/chain_metadata.dart';
import 'package:walletconnect_flutter_v2_wallet/models/page_data.dart';
import 'package:walletconnect_flutter_v2_wallet/pages/apps_page.dart';
import 'package:walletconnect_flutter_v2_wallet/pages/auth_page.dart';
import 'package:walletconnect_flutter_v2_wallet/pages/connect_page.dart';
import 'package:walletconnect_flutter_v2_wallet/pages/create_wallet.dart';
import 'package:walletconnect_flutter_v2_wallet/pages/pairings_page.dart';
import 'package:walletconnect_flutter_v2_wallet/pages/sessions_page.dart';
import 'package:walletconnect_flutter_v2_wallet/pages/settings_page.dart';
import 'package:walletconnect_flutter_v2_wallet/utils/constants.dart';
import 'package:flutter/material.dart';
import 'package:walletconnect_flutter_v2_wallet/utils/crypto/helpers.dart';
import 'package:walletconnect_flutter_v2_wallet/utils/string_constants.dart';
import 'package:walletconnect_flutter_v2_wallet/widgets/event_widget.dart';
import 'package:web3modal_flutter/services/w3m_service/i_w3m_service.dart';
import 'package:web3modal_flutter/services/w3m_service/w3m_service.dart';

import 'imports.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  DeepLinkHandler.initListener();
  runApp(const MyApp());
  // Magic.instance = Magic("pk_live_495EA8B35999D1BF");
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: StringConstants.appTitle,
      debugShowCheckedModeBanner: false,
      home: MyHomePage(),
      theme: ThemeData(
        brightness: Brightness.dark,
        colorScheme: ColorScheme.fromSeed(
            seedColor: Colors.deepPurple, brightness: Brightness.dark),
        useMaterial3: true,
      ),
    );
  }
}

class MyHomePage extends StatefulWidget with GetItStatefulWidgetMixin {
  MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> with GetItStateMixin {
  bool _initializing = true;

  Web3App? _web3App;

  List<PageData> _pageDatas = [];
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    initialize();
  }

  Future<void> initialize() async {
    String flavor = '-${const String.fromEnvironment('FLUTTER_APP_FLAVOR')}';
    flavor = flavor.replaceAll('-production', '');
    _web3App = Web3App(
      core: Core(
        projectId: '3bd2c24308cacc6a68925788160c7409',
      ),
      metadata: PairingMetadata(
        name: 'Sample dApp Flutter',
        description: 'WalletConnect\'s sample dapp with Flutter',
        url: 'https://walletconnect.com/',
        icons: [
          'https://images.prismic.io/wallet-connect/65785a56531ac2845a260732_WalletConnect-App-Logo-1024X1024.png'
        ],
        redirect: Redirect(
          native: 'wcflutterdapp$flavor://',
          // universal: 'https://walletconnect.com',
        ),
      ),
    );

    _web3App!.core.addLogListener(_logListener);

    // Register event handlers
    _web3App!.core.relayClient.onRelayClientError.subscribe(
      _relayClientError,
    );
    _web3App!.core.relayClient.onRelayClientConnect.subscribe(_setState);
    _web3App!.core.relayClient.onRelayClientDisconnect.subscribe(_setState);
    _web3App!.core.relayClient.onRelayClientMessage.subscribe(
      _onRelayMessage,
    );

    _web3App!.onSessionPing.subscribe(_onSessionPing);
    _web3App!.onSessionEvent.subscribe(_onSessionEvent);
    _web3App!.onSessionUpdate.subscribe(_onSessionUpdate);
    _web3App!.onSessionConnect.subscribe(_onSessionConnect);
    _web3App!.onSessionAuthResponse.subscribe(_onSessionAuthResponse);

    await _web3App!.init();

    // Loop through all the chain data
    for (final ChainMetadata chain in ChainData.allChains) {
      // Loop through the events for that chain
      for (final event in getChainEvents(chain.type)) {
        _web3App!.registerEventHandler(
          chainId: chain.chainId,
          event: event,
        );
      }
    }

    GetIt.I.registerSingleton<IBottomSheetService>(BottomSheetService());
    GetIt.I.registerSingleton<IKeyService>(KeyService());
    print('registering w3m service');
    GetIt.I.registerSingleton<IW3mService>(W3mService());

    await GetIt.I<IW3mService>().initializeW3MService();

    final web3WalletService = Web3WalletService();
    await web3WalletService.create();
    GetIt.I.registerSingleton<IWeb3WalletService>(web3WalletService);

    // Support EVM Chains
    for (final chainData in ChainData.eip155Chains) {
      GetIt.I.registerSingleton<EVMService>(
        EVMService(chainSupported: chainData),
        instanceName: chainData.chainId,
      );
    }

    // Support Kadena Chains
    for (final chainData in ChainData.kadenaChains) {
      GetIt.I.registerSingleton<KadenaService>(
        KadenaService(chainSupported: chainData),
        instanceName: chainData.chainId,
      );
    }

    // Support Polkadot Chains
    for (final chainData in ChainData.polkadotChains) {
      GetIt.I.registerSingleton<PolkadotService>(
        PolkadotService(chainSupported: chainData),
        instanceName: chainData.chainId,
      );
    }

    // Support Solana Chains
    for (final chainData in ChainData.solanaChains) {
      GetIt.I.registerSingleton<SolanaService>(
        SolanaService(chainSupported: chainData),
        instanceName: chainData.chainId,
      );
    }

    // Support Cosmos Chains
    for (final chainData in ChainData.cosmosChains) {
      GetIt.I.registerSingleton<CosmosService>(
        CosmosService(chainSupported: chainData),
        instanceName: chainData.chainId,
      );
    }

    await web3WalletService.init();

    web3WalletService.web3wallet.core.relayClient.onRelayClientConnect
        .subscribe(
      _setState,
    );
    web3WalletService.web3wallet.core.relayClient.onRelayClientDisconnect
        .subscribe(
      _setState,
    );

    setState(() {
      _pageDatas = [
        PageData(
          page: AppsPage(),
          title: StringConstants.connectPageTitle,
          icon: Icons.swap_vert_circle_outlined,
        ),
        PageData(
          page: ConnectPage(web3App: _web3App!),
          title: StringConstants.connectPageTitle,
          icon: Icons.home,
        ),
        PageData(
          page: PairingsPage(web3App: _web3App!),
          title: StringConstants.pairingsPageTitle,
          icon: Icons.vertical_align_center_rounded,
        ),
        PageData(
          page: SessionsPage(web3App: _web3App!),
          title: StringConstants.sessionsPageTitle,
          icon: Icons.workspaces_filled,
        ),
        PageData(
          page: AuthPage(web3App: _web3App!),
          title: StringConstants.authPageTitle,
          icon: Icons.lock,
        ),
        // PageData(
        //   page: const Center(
        //     child: Text(
        //       'Inbox (Not Implemented)',
        //       style: StyleConstants.bodyText,
        //     ),
        //   ),
        //   title: 'Inbox',
        //   icon: Icons.inbox_rounded,
        // ),
        PageData(
          page: const SettingsPage(),
          title: 'Settings',
          icon: Icons.settings_outlined,
        ),
      ];

      _initializing = false;
    });
  }

  void _onSessionConnect(SessionConnect? event) {
    log('[SampleDapp] _onSessionConnect $event');
  }

  void _onSessionAuthResponse(SessionAuthResponse? response) {
    log('[SampleDapp] _onSessionAuthResponse $response');
  }

  void _relayClientError(ErrorEvent? event) {
    debugPrint('[SampleDapp] _relayClientError ${event?.error}');
    _setState('');
  }

  void _setState(dynamic args) => setState(() {});
  @override
  void dispose() {
    // Unregister event handlers
    _web3App!.core.removeLogListener(_logListener);

    _web3App!.core.relayClient.onRelayClientError.unsubscribe(
      _relayClientError,
    );
    _web3App!.core.relayClient.onRelayClientConnect.unsubscribe(_setState);
    _web3App!.core.relayClient.onRelayClientDisconnect.unsubscribe(_setState);
    _web3App!.core.relayClient.onRelayClientMessage.unsubscribe(
      _onRelayMessage,
    );

    _web3App!.onSessionPing.unsubscribe(_onSessionPing);
    _web3App!.onSessionEvent.unsubscribe(_onSessionEvent);
    _web3App!.onSessionUpdate.unsubscribe(_onSessionUpdate);
    _web3App!.onSessionConnect.subscribe(_onSessionConnect);
    _web3App!.onSessionAuthResponse.subscribe(_onSessionAuthResponse);

    super.dispose();
  }

  void _logListener(LogEvent event) {
    if (event.level == Level.debug) {
      // TODO send to mixpanel
      log('[Mixpanel] ${event.message}');
    } else {
      debugPrint('[Logger] ${event.level.name}: ${event.message}');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_initializing) {
      return const Material(
        child: Center(
          child: CircularProgressIndicator(
            color: StyleConstants.primaryColor,
          ),
        ),
      );
    }

    final List<Widget> navRail = [];
    if (MediaQuery.of(context).size.width >= Constants.smallScreen) {
      navRail.add(_buildNavigationRail());
    }
    navRail.add(
      Expanded(
        child: _pageDatas[_selectedIndex].page,
      ),
    );

    final web3Wallet = GetIt.I<IWeb3WalletService>().web3wallet;
    return Scaffold(
      appBar: AppBar(
        // title: Text(
        //   _pageDatas[_selectedIndex].title,
        //   style: const TextStyle(color: Colors.black),
        // ),
        actions: [
          const Text('Relay '),
          CircleAvatar(
            radius: 6.0,
            backgroundColor: web3Wallet.core.relayClient.isConnected
                ? Colors.green
                : Colors.red,
          ),
          const SizedBox(width: 16.0),
        ],
      ),
      // body: BottomSheetListener(
      //   child: Row(
      //     mainAxisSize: MainAxisSize.max,
      //     children: navRail,
      //   ),
      // ),
      body: LaWalletScreen(),
      // bottomNavigationBar:
      //     MediaQuery.of(context).size.width < Constants.smallScreen
      //         ? _buildBottomNavBar()
      //         : null,
    );
  }

  Widget _buildBottomNavBar() {
    return BottomNavigationBar(
      currentIndex: _selectedIndex,
      unselectedItemColor: Colors.grey,
      selectedItemColor: Colors.black,
      // called when one tab is selected
      onTap: (int index) {
        setState(() {
          _selectedIndex = index;
        });
      },
      // bottom tab items
      items: _pageDatas
          .map(
            (e) => BottomNavigationBarItem(
              icon: Icon(e.icon),
              label: e.title,
            ),
          )
          .toList(),
    );
  }

  Widget _buildNavigationRail() {
    return NavigationRail(
      backgroundColor: StyleConstants.backgroundColor,
      selectedIndex: _selectedIndex,
      onDestinationSelected: (int index) {
        setState(() {
          _selectedIndex = index;
        });
      },
      labelType: NavigationRailLabelType.selected,
      destinations: _pageDatas
          .map(
            (e) => NavigationRailDestination(
              icon: Icon(e.icon),
              label: Text(e.title),
            ),
          )
          .toList(),
    );
  }

  void _onSessionPing(SessionPing? args) {
    debugPrint('[SampleDapp] _onSessionPing $args');
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return EventWidget(
          title: StringConstants.receivedPing,
          content: 'Topic: ${args!.topic}',
        );
      },
    );
  }

  void _onSessionEvent(SessionEvent? args) {
    debugPrint('[SampleDapp] _onSessionEvent $args');
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return EventWidget(
          title: StringConstants.receivedEvent,
          content:
              'Topic: ${args!.topic}\nEvent Name: ${args.name}\nEvent Data: ${args.data}',
        );
      },
    );
  }

  void _onSessionUpdate(SessionUpdate? args) {
    debugPrint('[SampleDapp] _onSessionUpdate $args');
  }

  void _onRelayMessage(MessageEvent? args) async {
    if (args != null) {
      try {
        final payloadString = await _web3App!.core.crypto.decode(
          args.topic,
          args.message,
        );
        final data = jsonDecode(payloadString ?? '{}') as Map<String, dynamic>;
        debugPrint('[SampleDapp] _onRelayMessage data $data');
      } catch (e) {
        debugPrint('[SampleDapp] _onRelayMessage error $e');
      }
    }
  }
}
