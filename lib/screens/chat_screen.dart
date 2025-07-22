import 'package:flutter/material.dart';

class ChatMessage {
  final String type; // 'user', 'ai', 'rich_response'
  final String content;
  final Map<String, dynamic>? richData; // For rich responses
  final DateTime timestamp;

  ChatMessage({
    required this.type,
    required this.content,
    this.richData,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();
}

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<ChatMessage> _messages = [];
  bool _isTyping = false;

  final List<String> _suggestionChips = [
    "How much did I spend on groceries last month?",
    "Do I have any detergent at home?",
    "What can I cook with chicken and rice?",
    "Show me my recent receipts",
    "Track my monthly expenses",
    "What's expiring soon?",
  ];

  @override
  void initState() {
    super.initState();
    // Add welcome message
    _messages.add(
      ChatMessage(
        type: 'ai',
        content: "Hi, I'm RASEED. How can I help you today?",
      ),
    );
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _sendMessage(String message) {
    if (message.trim().isEmpty) return;

    setState(() {
      _messages.add(ChatMessage(type: 'user', content: message.trim()));
      _isTyping = true;
    });

    _messageController.clear();
    _scrollToBottom();

    // Simulate AI response
    _simulateAIResponse(message.trim());
  }

  void _simulateAIResponse(String userMessage) {
    Future.delayed(const Duration(milliseconds: 1500), () {
      if (!mounted) return;

      setState(() {
        _isTyping = false;

        // Check for rich response triggers
        if (userMessage.toLowerCase().contains('grocery') ||
            userMessage.toLowerCase().contains('spend')) {
          _messages.add(
            ChatMessage(
              type: 'rich_response',
              content: 'expense_chart',
              richData: {
                'title': 'Grocery Spending - Last Month',
                'amount': '\$342.50',
                'categories': [
                  {
                    'name': 'Fresh Produce',
                    'amount': 125.30,
                    'color': Colors.green,
                  },
                  {
                    'name': 'Dairy & Eggs',
                    'amount': 78.20,
                    'color': Colors.blue,
                  },
                  {
                    'name': 'Meat & Seafood',
                    'amount': 89.50,
                    'color': Colors.red,
                  },
                  {
                    'name': 'Pantry Items',
                    'amount': 49.50,
                    'color': Colors.orange,
                  },
                ],
              },
            ),
          );
        } else if (userMessage.toLowerCase().contains('detergent') ||
            userMessage.toLowerCase().contains('home')) {
          _messages.add(
            ChatMessage(
              type: 'rich_response',
              content: 'inventory_card',
              richData: {
                'item': 'Tide Liquid Detergent',
                'quantity': '2 bottles',
                'location': 'Laundry Room',
                'lastPurchased': '2 weeks ago',
                'status': 'In Stock',
              },
            ),
          );
        } else if (userMessage.toLowerCase().contains('cook') ||
            userMessage.toLowerCase().contains('recipe')) {
          _messages.add(
            ChatMessage(
              type: 'rich_response',
              content: 'recipe_card',
              richData: {
                'title': 'Chicken Fried Rice',
                'cookTime': '25 mins',
                'difficulty': 'Easy',
                'ingredients': [
                  'Chicken breast',
                  'Rice',
                  'Eggs',
                  'Soy sauce',
                  'Vegetables',
                ],
                'image':
                    'https://via.placeholder.com/200x120/4CAF50/white?text=Recipe',
              },
            ),
          );
        } else {
          // Regular text response
          _messages.add(
            ChatMessage(type: 'ai', content: _getAIResponse(userMessage)),
          );
        }
      });
      _scrollToBottom();
    });
  }

  String _getAIResponse(String userMessage) {
    final responses = [
      "I'd be happy to help you with that! Let me analyze your data.",
      "Based on your receipt history, here's what I found:",
      "Great question! I can help you track that information.",
      "Let me check your inventory and spending patterns for you.",
      "I've analyzed your recent purchases and here's my recommendation:",
    ];
    return responses[DateTime.now().millisecond % responses.length];
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _onSuggestionTap(String suggestion) {
    _sendMessage(suggestion);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          'RASEED AI Assistant',
          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 18),
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 1,
        shadowColor: Colors.black12,
      ),
      body: Column(
        children: [
          // Chat History
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              itemCount:
                  _messages.length +
                  (_isTyping ? 1 : 0) +
                  (_messages.length == 1 ? 1 : 0),
              itemBuilder: (context, index) {
                // Show suggestion chips after welcome message
                if (_messages.length == 1 && index == 1) {
                  return _buildSuggestionChips();
                }

                // Show typing indicator
                if (index == _messages.length) {
                  return _buildTypingIndicator();
                }

                final message = _messages[index];
                return _buildMessageBubble(message);
              },
            ),
          ),

          // Text Input Area
          _buildInputArea(),
        ],
      ),
    );
  }

  Widget _buildSuggestionChips() {
    return Container(
      margin: const EdgeInsets.only(top: 16, bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(left: 4, bottom: 12),
            child: Text(
              'Try asking:',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          SizedBox(
            height: 100,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _suggestionChips.length,
              itemBuilder: (context, index) {
                return Container(
                  margin: EdgeInsets.only(right: 12, left: index == 0 ? 4 : 0),
                  child: ActionChip(
                    label: Container(
                      constraints: const BoxConstraints(maxWidth: 200),
                      child: Text(
                        _suggestionChips[index],
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    backgroundColor: Colors.white,
                    side: BorderSide(color: Colors.grey[300]!),
                    onPressed: () => _onSuggestionTap(_suggestionChips[index]),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(ChatMessage message) {
    final isUser = message.type == 'user';

    if (message.type == 'rich_response') {
      return _buildRichResponse(message);
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Row(
        mainAxisAlignment:
            isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isUser) ...[
            CircleAvatar(
              radius: 16,
              backgroundColor: Theme.of(context).primaryColor,
              child: const Icon(Icons.smart_toy, size: 18, color: Colors.white),
            ),
            const SizedBox(width: 8),
          ],

          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: isUser ? Theme.of(context).primaryColor : Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 5,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Text(
                message.content,
                style: TextStyle(
                  color: isUser ? Colors.white : Colors.black87,
                  fontSize: 15,
                  height: 1.4,
                ),
              ),
            ),
          ),

          if (isUser) ...[
            const SizedBox(width: 8),
            CircleAvatar(
              radius: 16,
              backgroundColor: Colors.grey[300],
              child: const Icon(Icons.person, size: 18, color: Colors.grey),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildRichResponse(ChatMessage message) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: Theme.of(context).primaryColor,
            child: const Icon(Icons.smart_toy, size: 18, color: Colors.white),
          ),
          const SizedBox(width: 8),

          Expanded(
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: _buildRichContent(message),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRichContent(ChatMessage message) {
    switch (message.content) {
      case 'expense_chart':
        return _buildExpenseChart(message.richData!);
      case 'inventory_card':
        return _buildInventoryCard(message.richData!);
      case 'recipe_card':
        return _buildRecipeCard(message.richData!);
      default:
        return Text(message.content);
    }
  }

  Widget _buildExpenseChart(Map<String, dynamic> data) {
    final categories = data['categories'] as List<Map<String, dynamic>>;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.bar_chart,
              color: Theme.of(context).primaryColor,
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              data['title'],
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
            ),
          ],
        ),
        const SizedBox(height: 12),

        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.grey[50],
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              Text(
                data['amount'],
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).primaryColor,
                ),
              ),
              const SizedBox(height: 16),

              ...categories
                  .map(
                    (category) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        children: [
                          Container(
                            width: 12,
                            height: 12,
                            decoration: BoxDecoration(
                              color: category['color'],
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              category['name'],
                              style: const TextStyle(fontSize: 14),
                            ),
                          ),
                          Text(
                            '\$${category['amount'].toStringAsFixed(2)}',
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                  .toList(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildInventoryCard(Map<String, dynamic> data) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.inventory,
              color: Theme.of(context).primaryColor,
              size: 20,
            ),
            const SizedBox(width: 8),
            const Text(
              'Inventory Check',
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
            ),
          ],
        ),
        const SizedBox(height: 12),

        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.green[50],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.green[200]!),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                data['item'],
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 8),

              Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.green[600], size: 16),
                  const SizedBox(width: 4),
                  Text(
                    '${data['status']} - ${data['quantity']}',
                    style: TextStyle(
                      color: Colors.green[700],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              Text(
                'Location: ${data['location']}',
                style: const TextStyle(color: Colors.grey),
              ),
              Text(
                'Last purchased: ${data['lastPurchased']}',
                style: const TextStyle(color: Colors.grey),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildRecipeCard(Map<String, dynamic> data) {
    final ingredients = data['ingredients'] as List<String>;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.restaurant,
              color: Theme.of(context).primaryColor,
              size: 20,
            ),
            const SizedBox(width: 8),
            const Text(
              'Recipe Suggestion',
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
            ),
          ],
        ),
        const SizedBox(height: 12),

        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.orange[50],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.orange[200]!),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                data['title'],
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 18,
                ),
              ),
              const SizedBox(height: 8),

              Row(
                children: [
                  Icon(Icons.timer, size: 16, color: Colors.orange[600]),
                  const SizedBox(width: 4),
                  Text(data['cookTime']),
                  const SizedBox(width: 16),
                  Icon(
                    Icons.signal_cellular_alt,
                    size: 16,
                    color: Colors.orange[600],
                  ),
                  const SizedBox(width: 4),
                  Text(data['difficulty']),
                ],
              ),
              const SizedBox(height: 12),

              const Text(
                'Ingredients:',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 4),

              ...ingredients
                  .take(3)
                  .map(
                    (ingredient) => Padding(
                      padding: const EdgeInsets.only(bottom: 2),
                      child: Text('• $ingredient'),
                    ),
                  )
                  .toList(),

              if (ingredients.length > 3)
                Text('• +${ingredients.length - 3} more ingredients'),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTypingIndicator() {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: Theme.of(context).primaryColor,
            child: const Icon(Icons.smart_toy, size: 18, color: Colors.white),
          ),
          const SizedBox(width: 8),

          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 5,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildTypingDot(0),
                const SizedBox(width: 4),
                _buildTypingDot(1),
                const SizedBox(width: 4),
                _buildTypingDot(2),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTypingDot(int index) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 600 + (index * 200)),
      builder: (context, value, child) {
        return Transform.scale(
          scale: 0.5 + (0.5 * value),
          child: Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: Colors.grey[400],
              shape: BoxShape.circle,
            ),
          ),
        );
      },
    );
  }

  Widget _buildInputArea() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.grey[200]!)),
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _messageController,
                decoration: InputDecoration(
                  hintText: 'Ask me anything about your finances...',
                  hintStyle: TextStyle(color: Colors.grey[500]),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide(color: Colors.grey[300]!),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide(color: Colors.grey[300]!),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide(
                      color: Theme.of(context).primaryColor,
                    ),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                  filled: true,
                  fillColor: Colors.grey[50],
                ),
                maxLines: null,
                textCapitalization: TextCapitalization.sentences,
                onSubmitted: _sendMessage,
              ),
            ),
            const SizedBox(width: 12),

            Container(
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor,
                shape: BoxShape.circle,
              ),
              child: IconButton(
                icon: const Icon(Icons.send, color: Colors.white),
                onPressed: () => _sendMessage(_messageController.text),
                padding: const EdgeInsets.all(12),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
