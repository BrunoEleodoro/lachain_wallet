import 'package:flutter/material.dart';

class SwapTokensPage extends StatefulWidget {
  @override
  _SwapTokensPageState createState() => _SwapTokensPageState();
}

class CurrencySwapCard extends StatelessWidget {
  final String amount;
  final String currency;
  final String dollarValue;
  final String balance;

  const CurrencySwapCard({
    Key? key,
    required this.amount,
    required this.currency,
    required this.dollarValue,
    required this.balance,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                amount,
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      backgroundColor:
                          currency == 'ETH' ? Colors.blue : Colors.orange,
                      radius: 12,
                      child: Text(
                        currency == 'ETH' ? '♦' : 'Ð',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                    SizedBox(width: 8),
                    Text(currency),
                    Icon(Icons.chevron_right),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(dollarValue, style: TextStyle(color: Colors.grey)),
              Row(
                children: [
                  Text('Balance: $balance',
                      style: TextStyle(color: Colors.grey)),
                  SizedBox(width: 4),
                  Text('Max', style: TextStyle(color: Colors.purple)),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SwapTokensPageState extends State<SwapTokensPage> {
  String _selectedTokenFrom = 'ETH';
  String _selectedTokenTo = 'DAI';
  TextEditingController _amountController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Swap Tokens'),
        actions: [
          IconButton(
            icon: Icon(Icons.settings),
            onPressed: () {},
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: 20),
              CurrencySwapCard(
                amount: '1',
                currency: 'LAC',
                dollarValue: '\$1,642.59',
                balance: '3.789',
              ),
              SizedBox(height: 10),
              Center(
                child: Container(
                  padding: EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.grey[200],
                  ),
                  child: Icon(Icons.swap_vert, color: Colors.blue),
                ),
              ),
              SizedBox(height: 10),
              CurrencySwapCard(
                amount: '1706.68',
                currency: 'DAI',
                dollarValue: '\$1,706.68',
                balance: '10.23',
              ),
              SizedBox(height: 20),
              Center(
                child: Text(
                  '1 ETH = 1,706.68 DAI (\$1,707.85)',
                  style: TextStyle(color: Colors.grey),
                ),
              ),
              SizedBox(height: 20),
              ElevatedButton(
                child: Text('Review swap'),
                style: ElevatedButton.styleFrom(
                  minimumSize: Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(25),
                  ),
                ),
                onPressed: () {},
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTokenDropdown(
      String selectedToken, ValueChanged<String?> onChanged) {
    return DropdownButton<String>(
      value: selectedToken,
      onChanged: onChanged,
      items: <String>['ETH', 'DAI', 'USDC', 'WBTC']
          .map<DropdownMenuItem<String>>((String value) {
        return DropdownMenuItem<String>(
          value: value,
          child: Text(value),
        );
      }).toList(),
    );
  }

  void _swapTokens() {
    // Implement the logic to swap tokens here
    // For now, just show a dialog with the selected values
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Swap Confirmation'),
          content: Text(
              'Swapping ${_amountController.text} $_selectedTokenFrom to $_selectedTokenTo'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                // Add the actual swap logic here
              },
              child: Text('Confirm'),
            ),
          ],
        );
      },
    );
  }
}
