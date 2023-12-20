import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:urride_driver/constant/constant.dart';
import 'package:urride_driver/constant/show_toast_dialog.dart';
import 'package:urride_driver/model/ride_model.dart';
import 'package:urride_driver/model/trancation_model.dart';
import 'package:urride_driver/model/user_model.dart';
import 'package:urride_driver/page/add_bank_details/show_bank_details.dart';
import 'package:urride_driver/page/auth_screens/login_screen.dart';
import 'package:urride_driver/page/car_service_history/car_service_history_screen.dart';
import 'package:urride_driver/page/contact_us/contact_us_screen.dart';
import 'package:urride_driver/page/create_ride/create_ride_screen.dart';
import 'package:urride_driver/page/dash_board.dart';
import 'package:urride_driver/page/document_status/document_status_screen.dart';
import 'package:urride_driver/page/localization_screens/localization_screen.dart';
import 'package:urride_driver/page/my_profile/my_profile_screen.dart';
import 'package:urride_driver/page/new_ride_screens/new_ride_screen.dart';
import 'package:urride_driver/page/privacy_policy/privacy_policy_screen.dart';
import 'package:urride_driver/page/terms_of_service/terms_of_service_screen.dart';
import 'package:urride_driver/page/wallet/wallet_screen.dart';
import 'package:urride_driver/service/api.dart';
import 'package:urride_driver/utils/Preferences.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:location/location.dart';

class DashBoardController extends GetxController {
  Location location = Location();
  late StreamSubscription<LocationData> locationSubscription;
  RxString totalEarn = "1".obs;

  @override
  void onInit() {
    getUsrData();
    locationSubscription = location.onLocationChanged.listen((event) {});
    getCurrentLocation();
    updateToken();
    updateCurrentLocation();
    getPaymentSettingData();

    super.onInit();
  }

  updateToken() async {
    // use the returned token to send messages to users from your custom server
    String? token = await FirebaseMessaging.instance.getToken();
    if (token != null) {
      updateFCMToken(token);
    }
  }

  getCurrentLocation() async {
    LocationData location = await Location().getLocation();
    setCurrentLocation(
        location.latitude.toString(), location.longitude.toString());
  }

  UserModel? userModel;

  getUsrData() async {
    userModel = Constant.getUserData();

    isActive.value = userModel!.userData!.online == "yes" ? true : false;

    final response = await http.get(
        Uri.parse(
            "${API.walletHistory}?id_diver=${Preferences.getInt(Preferences.userId)}"),
        headers: API.header);

    Map<String, dynamic> responseBody = json.decode(response.body);

    if (response.statusCode == 200 && responseBody['success'] == "success") {
      TruncationModel model = TruncationModel.fromJson(responseBody);

      totalEarn.value = model.totalEarnings!.toString();
    } else if (response.statusCode == 200 &&
        responseBody['success'] == "Failed") {
    } else {}
  }

  RxBool isActive = true.obs;

  RxInt selectedDrawerIndex = 0.obs;

  final drawerItems = [
    DrawerItem('', CupertinoIcons.car_detailed),
    DrawerItem('All Rides', CupertinoIcons.car_detailed),
    DrawerItem('Documents', Icons.domain_verification),
    DrawerItem('My Profile', Icons.person_outline),
    // DrawerItem('My Earnings', Icons.account_balance_wallet_outlined),
    DrawerItem('Add Bank', Icons.account_balance),
    DrawerItem('Change Language', Icons.language),
    DrawerItem('Contact Us', Icons.rate_review_outlined),
    DrawerItem('Terms & Conditions', Icons.design_services),
    DrawerItem('Privacy Policy', Icons.privacy_tip),
    DrawerItem('SignOut', Icons.logout),
  ];

  onSelectItem(int index) {
    if (index == 9) {
      Preferences.clearKeyData(Preferences.isLogin);
      Preferences.clearKeyData(Preferences.user);
      Preferences.clearKeyData(Preferences.userId);
      Get.offAll(LoginScreen());
    } else {
      selectedDrawerIndex.value = index;
    }
    Get.back();
  }

  updateCurrentLocation({RideData? data}) async {
    RideData? rideData = data != null ? data : Constant.getCurrentRideData();
    LocationData currentLocation;
    Location location = Location();

    if (rideData != null) {
      String orderId = "";
      if (rideData.rideType! == 'driver') {
        orderId =
        '${rideData.idUserApp}-${rideData.id}-${rideData.idConducteur}';
      } else {
        orderId = (double.parse(rideData.idUserApp!) <
            double.parse(rideData.idConducteur!))
            ? '${rideData.idUserApp}-${rideData.id}-${rideData.idConducteur}'
            : '${rideData.idConducteur}-${rideData.id}-${rideData.idUserApp}';
      }
      PermissionStatus permissionStatus = await location.hasPermission();
      if (permissionStatus == PermissionStatus.granted) {
        location.enableBackgroundMode(enable: true);

        locationSubscription =
            location.onLocationChanged.listen((locationData) {
              currentLocation = locationData;
              if (rideData.statut.toString() == "on ride" ||
                  rideData.statut.toString() == "confirmed") {
                var locationUpdate;
                Constant.locationUpdate.doc(orderId).set({
                  'driver_latitude': currentLocation.latitude,
                  'driver_longitude': currentLocation.longitude,
                  'rotation': currentLocation.heading,
                  'user_id': rideData.idUserApp!,
                  'driver_id': rideData.idConducteur!,
                  'ride_type': rideData.rideType!,
                });
              }
            });
      } else {
        location.requestPermission().then((permissionStatus) {
          if (permissionStatus == PermissionStatus.granted) {
            location.enableBackgroundMode(enable: true);

            locationSubscription =
                location.onLocationChanged.listen((locationData) {
                  currentLocation = locationData;
                  if (rideData.statut.toString() == "on ride" ||
                      rideData.statut.toString() == "confirmed") {
                    Constant.locationUpdate.doc(orderId).set({
                      'driver_latitude': currentLocation.latitude,
                      'driver_longitude': currentLocation.longitude,
                      'rotation': currentLocation.heading,
                      'user_id': rideData.idUserApp!,
                      'driver_id': rideData.idConducteur!,
                      'ride_type': rideData.rideType!,
                    });
                  }
                });
          }
        });
      }
    }
  }

  deleteCurrentOrderLocation() {
    RideData? rideData = Constant.getCurrentRideData();
    if (rideData != null) {
      String orderId = "";
      if (rideData.rideType! == 'driver') {
        orderId =
        '${rideData.idUserApp}-${rideData.id}-${rideData.idConducteur}';
      } else {
        orderId = (double.parse(rideData.idUserApp.toString()) <
            double.parse(rideData.idConducteur!))
            ? '${rideData.idUserApp}-${rideData.id}-${rideData.idConducteur}'
            : '${rideData.idConducteur}-${rideData.id}-${rideData.idUserApp}';
      }
      Location location = Location();
      location.enableBackgroundMode(enable: false);
      Constant.locationUpdate.doc(orderId).delete().then((value) async {
        await updateCurrentLocation(data: rideData);
        Preferences.clearKeyData(Preferences.currentRideData);
        locationSubscription.cancel();
      });
    }
  }

  getDrawerItemWidget(int pos) {
    switch (pos) {
      case 0:
        return CreateRideScreen();
      case 1:
        return NewRideScreen();
    // case 1:
    //   return const ConfirmedScreen();
    // case 2:
    //   return const OnRideScreen();
    // case 3:
    //   return const CompletedScreen();
    // case 4:
    //   return const RejectedScreen();
      case 2:
        return DocumentStatusScreen();
      case 3:
        return MyProfileScreen();
      // case 4:
      //   return const CarServiceBookHistory();
      // case 5:
      //   return WalletScreen();
      case 4:
        return const ShowBankDetails();
      case 5:
        return const LocalizationScreens(intentType: "dashBoard");
      case 6:
        return const ContactUsScreen();
      case 7:
        return const TermsOfServiceScreen();
      case 8:
        return const PrivacyPolicyScreen();

      default:
        return Text("Error".toString());
    }
  }

  Future<dynamic> setCurrentLocation(String latitude, String longitude) async {
    try {
      Map<String, dynamic> bodyParams = {
        'id_user': Preferences.getInt(Preferences.userId),
        'user_cat': userModel!.userData!.userCat,
        'latitude': latitude,
        'longitude': longitude
      };
      final response = await http.post(Uri.parse(API.updateLocation),
          headers: API.header, body: jsonEncode(bodyParams));

      Map<String, dynamic> responseBody = json.decode(response.body);
      if (response.statusCode == 200) {
        return responseBody;
      } else {
        ShowToastDialog.showToast(
            'Something want wrong. Please try again later');
        throw Exception('Failed to load album');
      }
    } on TimeoutException catch (e) {
      ShowToastDialog.showToast(e.message.toString());
    } on SocketException catch (e) {
      ShowToastDialog.showToast(e.message.toString());
    } on Error catch (e) {
      ShowToastDialog.showToast(e.toString());
    } catch (e) {
      ShowToastDialog.showToast(e.toString());
    }
    return null;
  }

  Future<dynamic> updateFCMToken(String token) async {
    try {
      Map<String, dynamic> bodyParams = {
        'user_id': Preferences.getInt(Preferences.userId),
        'fcm_id': token,
        'device_id': "",
        'user_cat': userModel!.userData!.userCat
      };
      final response = await http.post(Uri.parse(API.updateToken),
          headers: API.header, body: jsonEncode(bodyParams));

      Map<String, dynamic> responseBody = json.decode(response.body);
      if (response.statusCode == 200) {
        return responseBody;
      } else {
        ShowToastDialog.showToast(
            'Something want wrong. Please try again later');
        throw Exception('Failed to load album');
      }
    } on TimeoutException catch (e) {
      ShowToastDialog.showToast(e.message.toString());
    } on SocketException catch (e) {
      ShowToastDialog.showToast(e.message.toString());
    } on Error catch (e) {
      ShowToastDialog.showToast(e.toString());
    } catch (e) {
      ShowToastDialog.showToast(e.toString());
    }
    return null;
  }

  Future<dynamic> changeOnlineStatus(bodyParams) async {
    try {
      ShowToastDialog.showLoader("Please wait");
      final response = await http.post(Uri.parse(API.changeStatus),
          headers: API.header, body: jsonEncode(bodyParams));

      Map<String, dynamic> responseBody = json.decode(response.body);
      if (response.statusCode == 200) {
        ShowToastDialog.closeLoader();
        return responseBody;
      } else {
        ShowToastDialog.closeLoader();
        ShowToastDialog.showToast(
            'Something want wrong. Please try again later');
        throw Exception('Failed to load album');
      }
    } on TimeoutException catch (e) {
      ShowToastDialog.closeLoader();
      ShowToastDialog.showToast(e.message.toString());
    } on SocketException catch (e) {
      ShowToastDialog.closeLoader();
      ShowToastDialog.showToast(e.message.toString());
    } on Error catch (e) {
      ShowToastDialog.closeLoader();
      ShowToastDialog.showToast(e.toString());
    } catch (e) {
      ShowToastDialog.closeLoader();
      ShowToastDialog.showToast(e.toString());
    }
    return null;
  }

  Future<dynamic> getPaymentSettingData() async {
    try {
      final response =
      await http.get(Uri.parse(API.paymentSetting), headers: API.header);

      Map<String, dynamic> responseBody = json.decode(response.body);
      if (response.statusCode == 200 && responseBody['success'] == "success") {
        Preferences.setString(
            Preferences.paymentSetting, jsonEncode(responseBody));
      } else if (response.statusCode == 200 &&
          responseBody['success'] == "Failed") {
      } else {
        ShowToastDialog.showToast(
            'Something want wrong. Please try again later');
        throw Exception('Failed to load album');
      }
    } on TimeoutException catch (e) {
      ShowToastDialog.showToast(e.message.toString());
    } on SocketException catch (e) {
      ShowToastDialog.showToast(e.message.toString());
    } on Error catch (e) {
      ShowToastDialog.showToast(e.toString());
    } catch (e) {
      ShowToastDialog.closeLoader();
      ShowToastDialog.showToast(e.toString());
    }
    return null;
  }
}
