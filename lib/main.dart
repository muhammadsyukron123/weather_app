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
  String? _city;
  String _iconUrl = '';

  @override
  void initState() {
    super.initState();
    _updateWeather();
    _getMapImage();
  }

  Future<Image> _getMapImage() async {
    String url = 'https://maps.googleapis.com/maps/api/staticmap?center=$_latitude,$_longitude=&zoom=16&size=600x300&maptype=roadmap&markers=color:purple%7Clabel:A%7C$_latitude,$_longitude&key=YourAPIKey';
    return Image.network(url);
  }

  Future<void> _updateWeather() async {
    LocationPermission permission = await Geolocator.requestPermission();
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      setState(() {
        _weather = 'Location permissions are denied.';
      });
      return;
    }
    if(permission == LocationPermission.whileInUse || permission == LocationPermission.always){
      setState(() {
        _weather = 'Location permissions are granted.';
      });
    }
    else{
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
        Uri.parse('http://api.openweathermap.org/data/2.5/weather?lat=${position.latitude}&lon=${position.longitude}&units=metric&appid=YourAPIKey'));
    if (response.statusCode == 200) {
      var data = jsonDecode(response.body);
      // await _getMapImage();
      String iconUrl = 'http://openweathermap.org/img/w/${data["weather"][0]["icon"]}.png';
      String weather = data['weather'][0]['description'];
      double temperatureC = data['main']['temp'];
      String city = data['name'];
      _temperatureC = temperatureC;

      setState(() {
        _weather = weather;
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
      child: Container(
        padding: EdgeInsets.all(16.0),
        child: ListView(
          children: [
            Card(
              child: ListTile(
                leading: _iconUrl == '' ? CircularProgressIndicator() : Image.network(_iconUrl),
                title: Text('$_weather', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),),
                subtitle: Text('$_city'),
                trailing: Text('$_temperatureC °C', style: TextStyle(fontSize: 20),),
              ),
            ),
            SizedBox(height: 20,),
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
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
    ),
  );
}

}