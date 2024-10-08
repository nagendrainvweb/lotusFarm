import 'package:cached_network_image/cached_network_image.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_neumorphic/flutter_neumorphic.dart';
import 'package:lotus_farm/style/app_colors.dart';
import 'package:lotus_farm/style/spacing.dart';
import 'package:lotus_farm/utils/utility.dart';

class AppCarousel extends StatefulWidget {
  bool autoScroll;
  List<String> bannerList;
  AppCarousel(this.autoScroll,
      {@required this.bannerList,
      this.onPageChanged,
      @required this.onBannerClicked});
  final Function onPageChanged;
  final Function onBannerClicked;
  @override
  _AppCarouselState createState() => _AppCarouselState();
}

class _AppCarouselState extends State<AppCarousel> {
  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    var size = MediaQuery.of(context).size;

    /*24 is for notification bar on Android*/
    final double itemHeight = (size.height - kToolbarHeight - 24) / 2;
    final double itemWidth = size.width / 2;
    return Container(
      //color: Colors.white,
      child: Stack(
        fit: StackFit.loose,
        children: <Widget>[
          Container(
            width: MediaQuery.of(context).size.width,
            height: 200,
            child: CarouselSlider(
              options: CarouselOptions(
                  autoPlay: widget.autoScroll,
                  enlargeCenterPage: true,
                  enableInfiniteScroll: widget.autoScroll,
                  viewportFraction: 1.0,
                  aspectRatio: (itemWidth / itemHeight),
                  initialPage: 0,
                  autoPlayCurve: Curves.linear,
                  onPageChanged: (index, reason) {
                    widget.onPageChanged(index, reason);
                  }),
              items: List.generate(
                widget.bannerList.length,
                (position) {
                  return InkWell(
                    onTap: () async {
                      widget.onBannerClicked(position);
                    },
                    child: Neumorphic(
                      margin: const EdgeInsets.symmetric(
                          horizontal: Spacing.defaultMargin,
                          vertical: Spacing.defaultMargin),
                      style: NeumorphicStyle(
                        //shape: NeumorphicShape.concave,
                        boxShape: NeumorphicBoxShape.roundRect(
                            BorderRadius.circular(12)),
                      ),
                      child: CachedNetworkImage(
                        width: double.maxFinite,
                        height: double.maxFinite,
                        imageUrl: widget.bannerList[position],
                        placeholder: (context, data) {
                          return Container(
                            child: new Center(
                              child: SizedBox(
                                height: 20,
                                width: 20,
                                child: new CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              ),
                            ),
                          );
                        },
                        errorWidget: (_, data, value) {
                          return Container(
                            child: Text("Error"),
                          );
                        },
                        fit: BoxFit.cover,
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
