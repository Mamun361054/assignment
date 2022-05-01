import 'dart:async';
import 'dart:convert';

import 'package:bloc/bloc.dart';
import 'package:dio/dio.dart';
import 'package:equatable/equatable.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/utils/utils.dart';
import '../models/weather_one_call_model.dart';
import '../resources/home_repository.dart';

part 'home_event.dart';

part 'home_state.dart';

class HomeBloc extends Bloc<HomeEvent, HomeState> {
  HomeBloc() : super(HomeInitial());
  final _repository = HomeRepository();

  double? lat;
  double? long;

  @override
  Stream<HomeState> mapEventToState(
    HomeEvent event,
  ) async* {
    if (event is GetHomeData) {
      yield* _mapGetHomeDataEventToState(event);
    }
    if (event is GetLocalData) {
      yield* _mapGetLocalDataEventToState(event);
    }
    if (event is LocationError) {
      yield* _mapLocationNotEnabledToState(event);
    }
  }

  Stream<HomeState> _mapLocationNotEnabledToState(LocationError event) async* {
    yield HomeLocationNotEnabled(event.error);
  }

  Stream<HomeState> _mapGetHomeDataEventToState(GetHomeData event) async* {
    yield HomeLoading();
    final prefs = await SharedPreferences.getInstance();
    prefs.setDouble('lat', event.lat);
    prefs.setDouble('long', event.long);

    Response response = await _repository.getHomeData(lat: event.lat, long: event.long);
    prefs.setString('home_data_response', response.toString());
    Response gRes = await _repository.getLocationName(lat: event.lat, long: event.long);

    if (response.statusCode == 200) {

      final weatherData = WeatherData.fromJson(response.data);

      final place = gRes.data['results'][0]["address_components"][1]["long_name"];

      prefs.setString('location_data_response', place);

      yield HomeSuccess(weatherData, place);
    } else {
      yield HomeFailed(response.data['message']);
    }
  }

  Stream<HomeState> _mapGetLocalDataEventToState(GetLocalData event) async* {
    yield HomeLoading();
    final prefs = await SharedPreferences.getInstance();
    final String? data = prefs.getString('home_data_response');
    final String? place = prefs.getString('location_data_response');

    final response = await json.decode(data!);

    if (response != null) {

      final weatherData = WeatherData.fromJson(response);

      yield HomeSuccess(weatherData, place!);
    } else {
      yield const HomeFailed('no data found');
    }
  }

  void getLocation({required bool isOnline}) async {
    try {
      Position pos = await determinePosition();
      lat = pos.latitude;
      long = pos.longitude;
      if(isOnline) {
        add(GetHomeData(lat: lat!, long: long!));
      } else {
        add(GetLocalData());
      }
    } catch (err) {
      add(LocationError(err.toString()));
    }
  }
}