import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class RectangularButton extends StatelessWidget {
  final String text;
  final Color color;
  final Color btnText;
  final VoidCallback onPressed;

  const RectangularButton({
    Key? key,
    required this.text,
    required this.color,
    required this.onPressed,
    required this.btnText,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ButtonStyle(
        padding: MaterialStateProperty.all(EdgeInsets.symmetric(horizontal: 40, vertical: 20)), // Increased padding
        backgroundColor: MaterialStateProperty.all(color),
        shape: MaterialStateProperty.all(RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))), // Increased border radius
        elevation: MaterialStateProperty.all(10), // Increased elevation
        shadowColor: MaterialStateProperty.all(Colors.black.withOpacity(0.7)), // Increased shadow opacity
        overlayColor: MaterialStateProperty.all(color.withOpacity(0.5)), // Set overlay color
      ),
      // Add ripple effect
      // Note: Ripple effect is automatically enabled on Material Design
      child: Ink(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8), // Same border radius as the button
        ),
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(8), // Same border radius as the button
          splashColor: color.withOpacity(0.5), // Set splash color
          child: Center(
            child: Text(
              text,
              style: GoogleFonts.poppins(color: btnText),
            ),
          ),
        ),
      ),
    );
  }
}


