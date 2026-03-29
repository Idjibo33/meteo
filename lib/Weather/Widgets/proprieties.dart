import 'package:flutter/material.dart';
import 'package:meteo/Helpers/format_date.dart';
import 'package:meteo/constants.dart';
import 'package:weather/weather.dart';

class Proprieties extends StatelessWidget {
  final Weather weather;
  const Proprieties({super.key, required this.weather});

  @override
  Widget build(BuildContext context) {
    return Column(
      spacing: 12,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,

          children: [
            Row(
              children: [
                SizedBox(
                  height: 35,
                  width: 35,
                  child: Image.asset('assets/6.png'),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Lever du soleil"),
                    Text(
                      formatHour(weather.sunrise!),
                      style: TextStyle(
                        color: couleurBleue,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            Spacer(),
            Row(
              children: [
                SizedBox(
                  height: 35,
                  width: 35,
                  child: Image.asset('assets/12.png'),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Coucher du soleil", style: TextStyle()),
                    Text(
                      formatHour(weather.sunset!),
                      style: TextStyle(
                        color: couleurBleue,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
        Divider(),
        Row(
          children: [
            Row(
              children: [
                SizedBox(
                  height: 35,
                  width: 35,
                  child: Image.asset('assets/13.png'),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Temperature max", style: TextStyle()),
                    Text(
                      weather.tempMin!.toString(),
                      style: TextStyle(
                        color: couleurBleue,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            Spacer(),
            Row(
              children: [
                SizedBox(
                  height: 35,
                  width: 35,
                  child: Image.asset('assets/14.png'),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Temperature max", style: TextStyle()),
                    Text(
                      weather.tempMax!.toString(),
                      style: TextStyle(
                        color: couleurBleue,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }
}
