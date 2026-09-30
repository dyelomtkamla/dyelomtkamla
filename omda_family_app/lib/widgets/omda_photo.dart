import 'package:flutter/material.dart';

const omdaGold = Color(0xFFC9A227);
const omdaNavy = Color(0xFF0E2A43);
const _asset = 'assets/omda.jpg';

/// صورة العمدة داخل إطار ذهبي. الضغط عليها يفتحها بحجم الشاشة.
class OmdaPhoto extends StatelessWidget {
  const OmdaPhoto({super.key, this.size = 44, this.showBadge = false});
  final double size;
  final bool showBadge;

  static void openFull(BuildContext context) {
    Navigator.of(context).push(PageRouteBuilder(
      opaque: false,
      barrierColor: Colors.black87,
      barrierDismissible: true,
      pageBuilder: (c, a1, a2) => GestureDetector(
        onTap: () => Navigator.pop(c),
        child: Center(
          child: InteractiveViewer(child: Image.asset(_asset)),
        ),
      ),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final photo = Container(
      width: size,
      height: size,
      padding: EdgeInsets.all(size * .04),
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(colors: [Color(0xFFE6C65C), omdaGold, Color(0xFF9B7A14)]),
      ),
      child: ClipOval(
        child: Image.asset(_asset, fit: BoxFit.cover, alignment: const Alignment(-.2, -.6)),
      ),
    );

    return GestureDetector(
      onTap: () => openFull(context),
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.topCenter,
        children: [
          photo,
          if (showBadge)
            Positioned(
              top: -8,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
                decoration: BoxDecoration(
                  color: omdaGold,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white, width: 2),
                ),
                child: const Text('العمدة',
                    style: TextStyle(color: omdaNavy, fontWeight: FontWeight.bold, fontSize: 12)),
              ),
            ),
        ],
      ),
    );
  }
}

/// شريط أعلى المناسبات القادمة: صورة العمدة يراها كل أفراد العائلة.
class OmdaBanner extends StatelessWidget {
  const OmdaBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 12, 12, 0),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: const LinearGradient(colors: [omdaNavy, Color(0xFF081B2C)]),
      ),
      child: const Row(
        children: [
          OmdaPhoto(size: 72),
          SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('العمدة - كبير العائلة',
                    style: TextStyle(color: Color(0xFFE6C65C), fontWeight: FontWeight.bold, fontSize: 16)),
                SizedBox(height: 4),
                Text('العائلة هي السند.. شاركونا أفراحكم ومناسباتكم وخلّونا دايماً على تواصل.',
                    style: TextStyle(color: Color(0xFFCFE0EE), fontSize: 12.5)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
