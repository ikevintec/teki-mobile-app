import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:teki_app/src/data/models/teki_model/paymentMethod.dart';

class PaymentCardWidget extends StatelessWidget {
  final PaymentMethod paymentMethod;
  final bool isSelecelted;
  final Function()? onTap;
  const PaymentCardWidget(
      {super.key,
      required this.paymentMethod,
      required this.isSelecelted,
      this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(8.0),
          decoration: BoxDecoration(
            color: isSelecelted
                ? Colors.blue.withOpacity(0.1)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(8.0),
            border: Border.all(
              color: isSelecelted ? Colors.blue : Colors.grey.withOpacity(0.5),
              width: 1.0,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              if (paymentMethod.formaPago == "EFECTIVO")
                Image.asset(
                  getImageFromPayment(paymentMethod.formaPago ?? ''),
                  width: 50,
                  height: 50,
                ),
              if (paymentMethod.formaPago != "EFECTIVO")
                SvgPicture.asset(
                  getImageFromPayment(paymentMethod.tipoTarjeta ?? ''),
                  width: 50,
                  height: 50,
                ),
              const SizedBox(height: 8.0),
              Text(
                paymentMethod.nombre ?? '',
                style: TextStyle(
                  fontSize: 14.0,
                  color: isSelecelted ? Colors.blue : Colors.black,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ));
  }
}

String getImageFromPayment(String payment) {
  String imagenUrl = '';

  if (payment.isEmpty) {
    return 'assets/images/payment/credit-card.svg';
  }
  switch (payment) {
    case 'EFECTIVO':
      imagenUrl = 'assets/images/payment/dinero.png';
      break;
    case 'VISA':
      imagenUrl = 'assets/images/payment/credit-card-visa.svg';
      break;
    case 'MASTERCARD':
      imagenUrl = 'assets/images/payment/credit-master-card.svg';
      break;
    case 'AMERICAN_EXPRESS':
      imagenUrl = 'assets/images/payment/american-express.svg';
      break;
    case 'DINERS':
      imagenUrl = 'assets/images/payment/diners-club.svg';
      break;
    default:
      imagenUrl = 'assets/images/payment/credit-card.svg';
      break;
  }
  return imagenUrl;
}
