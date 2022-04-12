import 'dart:convert';
import 'dart:math';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pretty_dio_logger/pretty_dio_logger.dart';
import 'package:stripe_payment/stripe_payment.dart';

class StripeTransactionResponse {
  String message;
  bool success;
  StripeTransactionResponse({
    required this.message,
    required this.success,
  });
}

class StripeServices {
  static String apiBase = 'https://api.stripe.com/v1';
  static String paymentApiUrl = '${StripeServices.apiBase}/payment_intents';
  static String secret =
      'sk_test_51KlrFxGlJld8OIPcs1dakzQlbbg6b5kTAjRMFiNdlbhXU4cNwBG4DtsrTXm7SpwmA1ly9aGd3cXS8D9pckoYNMml002jcsbjVh';

  static Map<String, String> headers = {
    'Authorization': 'Bearer ${StripeServices.secret}',
    'Content-Type': 'application/x-www-form-urlencoded'
  };

  static init() {
    StripePayment.setOptions(StripeOptions(
        publishableKey:
            'pk_test_51KlrFxGlJld8OIPcmwoN2ZiYrNSrgP0PBsnO6PpX7msjzsvX2MLuiUrwAn2iwlgyPwq3NDjpdURnrat6J9tEbnwi004NRS6uNJ',
        androidPayMode: 'test',
        merchantId: 'test'));
  }

  static Future<Map<String, dynamic>> createPaymentIntent(String amount, String currency) async {
    try {
      Map<String, dynamic> body = {
        'amount': amount,
        'currency': currency,
      };

      var dio = Dio();
      dio.interceptors.add(PrettyDioLogger(
          requestHeader: true,
          requestBody: true,
          responseBody: true,
          responseHeader: false,
          error: true,
          compact: true,
          maxWidth: 90));

      var response = await dio.post(paymentApiUrl, options: Options(headers: headers), data: body);
      return response.data;
    } catch (error) {
      print('error Happened');
      throw error;
    }
  }

  static Future<StripeTransactionResponse> payNowHandler(BuildContext context,
      {required String amount, required String currency}) async {
    try {
      final CreditCard testCard = CreditCard(
        number: '4111111111111111',
        expMonth: 08,
        expYear: 22,
      );
      var token = await StripePayment.createTokenWithCard(testCard);
      var paymentMethod = await StripePayment.paymentRequestWithCardForm(CardFormPaymentRequest());
      var paymentIntent = await StripeServices.createPaymentIntent(amount, currency);
      var response = await StripePayment.confirmPaymentIntent(
          PaymentIntent(clientSecret: paymentIntent['client_secret'], paymentMethodId: paymentMethod.id));

      if (response.status == 'succeeded') {
        showDialog(
            context: context,
            builder: (_) {
              return const AlertDialog(title: Text('Thành công'));
            });
        return StripeTransactionResponse(message: 'Transaction succeful', success: true);
      } else {
        showDialog(
            context: context,
            builder: (_) {
              return const AlertDialog(title: Text('Thất bại'));
            });
        return StripeTransactionResponse(message: 'Transaction failed', success: false);
      }
    } catch (error) {
      showDialog(
          context: context,
          builder: (_) {
            return const AlertDialog(title: Text('Cancelled'));
          });
      return StripeTransactionResponse(message: 'Transaction failed in the catch block', success: false);
    } on PlatformException catch (error) {
      return StripeServices.getErrorAndAnalyze(error);
    }
  }

  static getErrorAndAnalyze(err) {
    String message = 'Something went wrong';
    if (err.code == 'cancelled') {
      message = 'Transaction canceled';
    }
    return StripeTransactionResponse(message: message, success: false);
  }
}
