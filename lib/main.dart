import 'dart:ffi';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Weather App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: WeatherScreen(),
    );
  }
}

class WeatherScreen extends StatefulWidget {
  @override
  _WeatherScreenState createState() => _WeatherScreenState();
}

class _WeatherScreenState extends State<WeatherScreen> {
  String _weather = 'Loading...';
  double? _latitude;
  double? _longitude;
  double? _temperatureC;
  String? _temperatureCStr;
  String? _time;
  String? _address;
  String? _city;
  String _iconUrl = '';

  @override
  void initState() {
    super.initState();
    _updateWeather();
    _getMapImage();
  }



  Future<String> _getAddress(double latitude, double longitude) async {
    final url = Uri.parse(
        'https://maps.googleapis.com/maps/api/geocode/json?latlng=$latitude,$longitude&key=YourAPIKey');
    final response = await http.get(url);
    final resData = json.decode(response.body);
    final address = resData['results'][0]['formatted_address'];
    return address;
  }

  Future<String> _getCity(double latitude, double longitude) async {
    final url = Uri.parse(
        'https://maps.googleapis.com/maps/api/geocode/json?latlng=$latitude,$longitude&key=YourAPIKey');
    final response = await http.get(url);
    final resData = json.decode(response.body);
    final address = resData['results'][0]['address_components'][4]['long_name'];
    return address;
  }

  Future<Image> _getMapImage() async {
    String url = 'https://maps.googleapis.com/maps/api/staticmap?center=$_latitude,$_longitude=&zoom=16&size=600x300&maptype=roadmap&markers=color:red%7Clabel:A%7C$_latitude,$_longitude&key=YourApiKey';
    return Image.network(url);
  }

  Future<void> _updateWeather() async {
    LocationPermission permission = await Geolocator.requestPermission();
    if (permission == LocationPermission.denied) {
      setState(() {
        _weather = 'Location permissions are denied.';
      });
      return;
    }

    Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.low);
    _latitude = position.latitude;
    _longitude = position.longitude;
    print('${position.latitude}, ${position.longitude}');
    final response = await http.get(
        Uri.parse('http://api.openweathermap.org/data/2.5/weather?lat=${position.latitude}&lon=${position.longitude}&appid=yourappid'));
    if (response.statusCode == 200) {
      var data = jsonDecode(response.body);
      // await _getMapImage();
      String iconUrl = 'http://openweathermap.org/img/w/${data["weather"][0]["icon"]}.png';
      String weather = data['weather'][0]['description'];
      double temperatureK = data['main']['temp'];
      String address = await _getAddress(_latitude!, _longitude!);
      String city = await _getCity(_latitude!, _longitude!);
      _temperatureC = temperatureK - 273.15;
      _temperatureCStr = _temperatureC!.toStringAsFixed(1);

      setState(() {
        _weather = weather;
        _address = address;
        _city = city;
        _iconUrl = iconUrl;
      });
    } else {
      setState(() {
        _weather = 'Failed to load weather data.';
      });
    }
  }

  @override
Widget build(BuildContext context) {
  return Scaffold(
    appBar: AppBar(
      title: Text('Weather App'),
    ),
    body: RefreshIndicator(
      onRefresh: _updateWeather,
      child: ListView(
        children: [
          Card(
            child: ListTile(
              leading: _iconUrl == '' ? CircularProgressIndicator() : Image.network(_iconUrl),
              title: Text('$_weather', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),),
              subtitle: Text('$_city'),
              trailing: Text('$_temperatureCStr °C', style: TextStyle(fontSize: 20),),
            ),
          ),
          SizedBox(height: 20,),
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              // border: Border.all(
              //   width: 1,
              //   color: Theme.of(context).colorScheme.onSecondary.withOpacity(1),
              // ),
              color: Colors.white70,
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.5),
                  spreadRadius: 1,
                  blurRadius: 5,
                  offset: Offset(0, 3),
                ),
              ],
            ),
            padding: EdgeInsets.all(20),
            child: Column(
              children: [
                FutureBuilder<Image>(
                  future: _getMapImage(),
                  builder: (BuildContext context, AsyncSnapshot<Image> snapshot) {
                    if (snapshot.connectionState == ConnectionState.done) {
                      return snapshot.data!;
                    } else {
                      return CircularProgressIndicator();
                    }
                  },
                ),
                SizedBox(height: 5,),
                Text('latitude: $_latitude'),
                SizedBox(height: 5,),
                Text('longitude: $_longitude'),
              ],
            ),
          ),

        ],
      ),
    ),
  );
}

}