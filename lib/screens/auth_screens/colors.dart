import 'package:flutter/material.dart';

void showAppSnackBar(BuildContext context, String message, {bool isError = true}) {
  _showSnackBar(ScaffoldMessenger.of(context), message, isError: isError);
}

void showAppSnackBarFromMessenger(ScaffoldMessengerState messenger, String message, {bool isError = true}) {
  _showSnackBar(messenger, message, isError: isError);
}

void _showSnackBar(ScaffoldMessengerState messenger, String message, {bool isError = true}) {
  messenger
    ..clearSnackBars()
    ..showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 24),
        padding: EdgeInsets.zero,
        backgroundColor: Colors.transparent,
        elevation: 0,
        content: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: const Color(0xFF0D1520),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isError
                  ? const Color(0xFFFF4D6A).withValues(alpha: 0.5)
                  : const Color(0xFF00E5FF).withValues(alpha: 0.5),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: (isError ? const Color(0xFFFF4D6A) : const Color(0xFF00E5FF))
                    .withValues(alpha: 0.12),
                blurRadius: 16,
                spreadRadius: 1,
              ),
            ],
          ),
          child: Row(
            children: [
              Icon(
                isError ? Icons.error_outline_rounded : Icons.check_circle_outline_rounded,
                color: isError ? const Color(0xFFFF4D6A) : const Color(0xFF00E5FF),
                size: 18,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  message,
                  style: TextStyle(
                    color: isError
                        ? const Color(0xFFFF4D6A).withValues(alpha: 0.9)
                        : const Color(0xFF00E5FF).withValues(alpha: 0.9),
                    fontSize: 12,
                    fontFamily: 'monospace',
                    letterSpacing: 0.4,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
}

const Color kCyan = Color(0xFF00E5FF);
const Color kCyanDim = Color(0xFF00B8D4);
const Color kDarkBg = Color(0xFF050F12);
const Color kCardBg = Color(0xFF0A1A20);
const Color kBorderDim = Color(0xFF1A3A45);

const cyan = Color(0xFF00E5FF);
const bg = Color(0xFF080C10);
const card = Color(0xFF0D1520);
const border = Color(0xFF142030);