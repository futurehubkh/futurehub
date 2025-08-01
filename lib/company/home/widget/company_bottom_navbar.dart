import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:future_hub/common/shared/palette.dart';
import 'package:go_router/go_router.dart';

class CompanyBottomNavBar extends StatelessWidget {
  const CompanyBottomNavBar({super.key});

  @override
  Widget build(BuildContext context) {
    return Localizations.override(
      locale: Directionality.of(context) == TextDirection.rtl
          ? const Locale('en')
          : const Locale('ar'),
      context: context,
      child: Container(
        height: MediaQuery.of(context).size.height * 0.2,
        width: double.infinity,
        decoration: const BoxDecoration(
          color: Palette.primaryColor,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              SizedBox(
                width: MediaQuery.of(context).size.width * 0.3,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    Padding(
                      padding:
                          const EdgeInsets.all(5.0), // Adjust padding as needed
                      child: SvgPicture.asset(
                        'assets/icons/home-b.svg',
                        height: MediaQuery.of(context).size.width * 0.13,
                      ),
                    ),
                    InkWell(
                      onTap: () => context.push('/company/employee'),
                      // Navigator.push(
                      // context,
                      // MaterialPageRoute(
                      //     builder: (context) =>
                      //         const CompanyEmployeesScreen())),
                      child: Padding(
                        padding: const EdgeInsets.all(
                            1.0), // Adjust padding as needed
                        child: Image.asset(
                          'assets/images/man.png',
                          height: 25
                          ,
                            filterQuality:
                                FilterQuality.none, // Disable mipmapping
                            isAntiAlias: false,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(
                width: MediaQuery.of(context).size.width * 0.3,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    InkWell(
                      onTap: () => context.push('/company/soon'),
                      child: Padding(
                        padding: const EdgeInsets.all(
                            8.0), // Adjust padding as needed
                        child: Image.asset(
                          'assets/images/box.png',
                            filterQuality:
                                FilterQuality.none, // Disable mipmapping
                            isAntiAlias: false,
                          height: 25,
                        ),
                      ),
                    ),
                    InkWell(
                      onTap: () => context.push('/settings_screen'),
                      child: Padding(
                        padding: const EdgeInsets.all(
                            8.0), // Adjust padding as needed
                        child: SvgPicture.asset(
                          'assets/icons/setting-b.svg',
                          height: 27,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
