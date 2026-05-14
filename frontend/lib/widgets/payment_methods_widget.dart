import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:yumbook_app/state/payment_method_store.dart';
import '../data/countries.dart' as country_data;

class PaymentMethodsWidget extends StatefulWidget {
  const PaymentMethodsWidget({
    super.key,
    this.onMethodSelected,
  });

  final ValueChanged<PaymentMethodModel>? onMethodSelected;

  @override
  State<PaymentMethodsWidget> createState() => _PaymentMethodsWidgetState();
}

class _PaymentMethodsWidgetState extends State<PaymentMethodsWidget> {
  final _formKey = GlobalKey<FormState>();

  final _cardNumberCtrl = TextEditingController();
  final _expiryCtrl = TextEditingController();
  final _cvcCtrl = TextEditingController();
  final _nameCtrl = TextEditingController();

  String? _country;
  final _regionCtrl = TextEditingController();

  String? _selectedMethodId;
  bool _showAddCardForm = false;

  @override
  void initState() {
    super.initState();
    final methods = PaymentMethodStore.instance.methods;
    if (methods.isNotEmpty) {
      _selectedMethodId = methods.first.id;
    } else {
      _showAddCardForm = true;
    }
  }

  @override
  void dispose() {
    _cardNumberCtrl.dispose();
    _expiryCtrl.dispose();
    _cvcCtrl.dispose();
    _nameCtrl.dispose();
    _regionCtrl.dispose();
    super.dispose();
  }

  Future<void> _openPrivacyPolicy() async {
    final uri = Uri.parse('https://www.yumbook.io/privacy-policy');
    final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);

    if (!ok && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to open the link.')),
      );
    }
  }

  void _useSelectedCard() {
    final methods = PaymentMethodStore.instance.methods;
    final selected = methods.where((e) => e.id == _selectedMethodId).toList();

    if (selected.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a payment method.')),
      );
      return;
    }

    widget.onMethodSelected?.call(selected.first);
  }

  void _onSave() {
    if (_formKey.currentState?.validate() != true) return;

    if (_country == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a country or region.')),
      );
      return;
    }

    if (_regionCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a state / province / city.')),
      );
      return;
    }

    final digits = _cardNumberCtrl.text.replaceAll(RegExp(r'\D'), '');
    final last4 =
        digits.length >= 4 ? digits.substring(digits.length - 4) : '0000';

    final newMethod = PaymentMethodModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      brand: _detectCardBrand(digits),
      last4: last4,
      holderName: _nameCtrl.text.trim(),
      expiry: _expiryCtrl.text.trim(),
    );

    PaymentMethodStore.instance.addMethod(newMethod);

    _cardNumberCtrl.clear();
    _expiryCtrl.clear();
    _cvcCtrl.clear();
    _nameCtrl.clear();
    _regionCtrl.clear();

    setState(() {
      _country = null;
      _selectedMethodId = newMethod.id;
      _showAddCardForm = false;
    });

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Card saved successfully.')),
    );
  }

  String _detectCardBrand(String digits) {
    if (digits.startsWith('4')) return 'Visa';

    final firstTwo =
        digits.length >= 2 ? int.tryParse(digits.substring(0, 2)) : null;
    final firstFour =
        digits.length >= 4 ? int.tryParse(digits.substring(0, 4)) : null;

    if (firstTwo != null && firstTwo >= 51 && firstTwo <= 55) {
      return 'MasterCard';
    }

    if (firstFour != null && firstFour >= 2221 && firstFour <= 2720) {
      return 'MasterCard';
    }

    if (digits.startsWith('34') || digits.startsWith('37')) {
      return 'Amex';
    }

    if (digits.startsWith('35')) {
      return 'JCB';
    }

    return 'Card';
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: PaymentMethodStore.instance,
      builder: (context, _) {
        final methods = PaymentMethodStore.instance.methods;

        if (methods.isNotEmpty && _selectedMethodId == null) {
          _selectedMethodId = methods.first.id;
        }

        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 20),
            clipBehavior: Clip.antiAlias,
            decoration: const ShapeDecoration(
              color: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(12),
                  topRight: Radius.circular(12),
                ),
              ),
            ),
            child: Form(
              key: _formKey,
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const Text(
                      'Payment methods',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Color(0xFF383838),
                        fontSize: 24,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 20),

                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        methods.isEmpty
                            ? 'You have no saved payment methods.'
                            : 'Saved payment methods',
                        style: const TextStyle(
                          color: Color(0xFF383838),
                          fontSize: 16,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ),

                    if (methods.isNotEmpty) ...[
                      const SizedBox(height: 14),
                      ...methods.map((method) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: _SavedCardTile(
                            method: method,
                            isSelected: _selectedMethodId == method.id,
                            onTap: () {
                              setState(() {
                                _selectedMethodId = method.id;
                              });
                            },
                            onDelete: () {
                              PaymentMethodStore.instance.removeMethod(method.id);

                              final updated = PaymentMethodStore.instance.methods;
                              setState(() {
                                if (_selectedMethodId == method.id) {
                                  _selectedMethodId =
                                      updated.isNotEmpty ? updated.first.id : null;
                                }
                                if (updated.isEmpty) {
                                  _showAddCardForm = true;
                                }
                              });
                            },
                          ),
                        );
                      }),

                      const SizedBox(height: 8),

                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFD45425),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                            elevation: 0,
                          ),
                          onPressed: _useSelectedCard,
                          child: const Text(
                            'Use this card',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 12),

                      TextButton(
                        onPressed: () {
                          setState(() {
                            _showAddCardForm = !_showAddCardForm;
                          });
                        },
                        child: Text(
                          _showAddCardForm ? 'Hide add card form' : 'Add a new card',
                          style: const TextStyle(
                            color: Color(0xFFD45425),
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],

                    if (methods.isEmpty || _showAddCardForm) ...[
                      const SizedBox(height: 12),

                      const Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'Add a payment method',
                          style: TextStyle(
                            color: Color(0xFF383838),
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const SizedBox(height: 17),

                      _label('Card number'),
                      _cardNumberField(),
                      const SizedBox(height: 17),

                      Row(
                        children: [
                          Expanded(child: _expiryField()),
                          const SizedBox(width: 16),
                          Expanded(child: _cvcField()),
                        ],
                      ),
                      const SizedBox(height: 17),

                      _label('Full name'),
                      _nameField(),
                      const SizedBox(height: 17),

                      _label('Country or region'),
                      _countryDropdown(),
                      const SizedBox(height: 17),

                      _label('State / Province / City'),
                      _regionField(),
                      const SizedBox(height: 17),

                      const Text(
                        'By submitting your card details, you authorize future charges related to reservations or service fees, as permitted under terms and conditions.\n'
                        'We’ve updated our Privacy Policy to better explain how we collect, use, and protect your personal information.',
                        style: TextStyle(
                          color: Color(0xFF6E6E6E),
                          fontSize: 12,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),

                      GestureDetector(
                        onTap: _openPrivacyPolicy,
                        child: const Text(
                          'Review the policy',
                          style: TextStyle(
                            color: Color(0xFFB4B4B4),
                            fontSize: 12,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ),

                      const SizedBox(height: 17),

                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFD45425),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                            elevation: 0,
                          ),
                          onPressed: _onSave,
                          child: const Text(
                            'Save card',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  static Widget _label(String text) => Padding(
        padding: const EdgeInsets.fromLTRB(0, 0, 0, 5),
        child: Align(
          alignment: Alignment.centerLeft,
          child: Text(
            text,
            style: const TextStyle(
              fontSize: 16,
              color: Color(0xFF1E1E1E),
            ),
          ),
        ),
      );

  InputDecoration _inputDeco({required String hint, Widget? suffix}) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: Color(0xFFB4B4B4)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Color(0xFFD9D9D9)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Color(0xFFD9D9D9)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Color(0xFFD45425)),
      ),
      suffixIcon: suffix,
    );
  }

  Widget _cardNumberField() {
    return TextFormField(
      controller: _cardNumberCtrl,
      keyboardType: TextInputType.number,
      inputFormatters: [
        FilteringTextInputFormatter.digitsOnly,
        LengthLimitingTextInputFormatter(16),
        _CardNumberFormatter(),
      ],
      decoration: _inputDeco(
        hint: '1234 1234 1234 1234',
        suffix: Padding(
          padding: const EdgeInsets.only(right: 10),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Image.asset('assets/cards/amex.png', height: 18),
              const SizedBox(width: 6),
              Image.asset('assets/cards/mastercard.png', height: 18),
              const SizedBox(width: 6),
              Image.asset('assets/cards/visa.png', height: 18),
              const SizedBox(width: 6),
              Image.asset('assets/cards/jcb.png', height: 18),
            ],
          ),
        ),
      ),
      validator: (v) {
        final digits = (v ?? '').replaceAll(RegExp(r'\D'), '');
        if (digits.length != 16) {
          return 'Please enter a 16-digit card number.';
        }
        return null;
      },
    );
  }

  Widget _expiryField() {
    return TextFormField(
      controller: _expiryCtrl,
      keyboardType: TextInputType.number,
      inputFormatters: [
        FilteringTextInputFormatter.digitsOnly,
        LengthLimitingTextInputFormatter(4),
        _ExpiryFormatter(),
      ],
      decoration: _inputDeco(hint: 'MM / YY'),
      validator: (v) {
        final digits = (v ?? '').replaceAll(RegExp(r'\D'), '');
        if (digits.length != 4) {
          return 'Please enter a valid expiry (MM/YY).';
        }

        final mm = int.tryParse(digits.substring(0, 2));
        final yy = int.tryParse(digits.substring(2, 4));

        if (mm == null || yy == null) {
          return 'Please enter a valid expiry (MM/YY).';
        }

        if (mm < 1 || mm > 12) {
          return 'Invalid month (01-12).';
        }

        return null;
      },
    );
  }

  Widget _cvcField() {
    return TextFormField(
      controller: _cvcCtrl,
      keyboardType: TextInputType.number,
      inputFormatters: [
        FilteringTextInputFormatter.digitsOnly,
        LengthLimitingTextInputFormatter(4),
      ],
      decoration: _inputDeco(hint: 'CVC'),
      validator: (v) {
        final digits = (v ?? '').replaceAll(RegExp(r'\D'), '');
        if (digits.length < 3) return 'Please enter your CVC.';
        return null;
      },
    );
  }

  Widget _nameField() {
    return TextFormField(
      controller: _nameCtrl,
      textInputAction: TextInputAction.done,
      decoration: _inputDeco(hint: ''),
      validator: (v) {
        if ((v ?? '').trim().isEmpty) {
          return 'Please enter your full name.';
        }
        return null;
      },
    );
  }

  Widget _countryDropdown() {
    return DropdownButtonFormField<String>(
      initialValue: _country,
      isExpanded: true,
      decoration: _inputDeco(hint: 'Select a country'),
      items: country_data.kCountries
          .map(
            (c) => DropdownMenuItem<String>(
              value: c,
              child: Text(c),
            ),
          )
          .toList(),
      onChanged: (v) {
        setState(() {
          _country = v;
          _regionCtrl.clear();
        });
      },
      validator: (_) =>
          _country == null ? 'Please select a country or region.' : null,
    );
  }

  Widget _regionField() {
    return TextFormField(
      controller: _regionCtrl,
      textInputAction: TextInputAction.next,
      decoration: _inputDeco(hint: 'State / Province / City'),
      validator: (v) {
        if ((v ?? '').trim().isEmpty) {
          return 'Please enter a state / province / city.';
        }
        return null;
      },
    );
  }
}

class _SavedCardTile extends StatelessWidget {
  final PaymentMethodModel method;
  final bool isSelected;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _SavedCardTile({
    required this.method,
    required this.isSelected,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final brandLabel = method.brand == 'Card' ? 'Saved Card' : method.brand;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          border: Border.all(
            color: isSelected ? const Color(0xFFD45425) : const Color(0xFFE5E5E5),
            width: isSelected ? 1.5 : 1,
          ),
          borderRadius: BorderRadius.circular(12),
          color: Colors.white,
        ),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 28,
              decoration: BoxDecoration(
                color: const Color(0xFFF3F4F6),
                borderRadius: BorderRadius.circular(6),
              ),
              alignment: Alignment.center,
              child: Text(
                brandLabel == 'MasterCard'
                    ? 'MC'
                    : brandLabel == 'Visa'
                        ? 'VISA'
                        : brandLabel == 'Amex'
                            ? 'AMEX'
                            : brandLabel == 'JCB'
                                ? 'JCB'
                                : 'CARD',
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF383838),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '$brandLabel •••• ${method.last4}',
                    style: const TextStyle(
                      color: Color(0xFF383838),
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${method.holderName} · ${method.expiry}',
                    style: const TextStyle(
                      color: Color(0xFF6E6E6E),
                      fontSize: 12,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              const Padding(
                padding: EdgeInsets.only(right: 6),
                child: Icon(
                  Icons.check_circle,
                  color: Color(0xFFD45425),
                ),
              ),
            IconButton(
              onPressed: onDelete,
              icon: const Icon(
                Icons.delete_outline_rounded,
                color: Color(0xFF6E6E6E),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CardNumberFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digits = newValue.text.replaceAll(RegExp(r'\D'), '');
    final buffer = StringBuffer();

    for (int i = 0; i < digits.length; i++) {
      buffer.write(digits[i]);
      if ((i + 1) % 4 == 0 && i != digits.length - 1) {
        buffer.write(' ');
      }
    }

    final text = buffer.toString();
    return TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }
}

class _ExpiryFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digits = newValue.text.replaceAll(RegExp(r'\D'), '');
    String text;

    if (digits.length <= 2) {
      text = digits;
    } else {
      text =
          '${digits.substring(0, 2)} / ${digits.substring(2, digits.length.clamp(2, 4))}';
    }

    return TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }
}