import 'package:flutter/material.dart';

class IrisLogo extends StatelessWidget {
  final double size;
  final Color? color;

  const IrisLogo({
    super.key,
    this.size = 80.0,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color != null
            ? Color.fromRGBO(
                color!.r.toInt(), color!.g.toInt(), color!.b.toInt(), 0.1)
            : Color.fromRGBO(
                Theme.of(context).primaryColor.r.toInt(),
                Theme.of(context).primaryColor.g.toInt(),
                Theme.of(context).primaryColor.b.toInt(),
                0.1),
        border: Border.all(
          color: color ?? Theme.of(context).primaryColor,
          width: 2.0,
        ),
      ),
      child: Center(
        child: Icon(
          Icons.remove_red_eye,
          color: color ?? Theme.of(context).primaryColor,
          size: size * 0.5,
        ),
      ),
    );
  }
}
