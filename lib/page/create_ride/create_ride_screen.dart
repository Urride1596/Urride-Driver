import 'dart:convert';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:maps_launcher/maps_launcher.dart';
import 'package:pinput/pinput.dart';
import 'package:text_scroll/text_scroll.dart';
import 'package:urride_driver/constant/constant.dart';
import 'package:urride_driver/constant/show_toast_dialog.dart';
import 'package:urride_driver/controller/create_ride_controller.dart';
import 'package:urride_driver/model/customer_model.dart';
import 'package:urride_driver/model/tax_model.dart';
import 'package:urride_driver/page/new_ride_screens/new_ride_screen.dart';
import 'package:urride_driver/themes/button_them.dart';
import 'package:urride_driver/themes/constant_colors.dart';
import 'package:urride_driver/themes/custom_dialog_box.dart';
import 'package:urride_driver/utils/Preferences.dart';
import 'package:dropdown_search/dropdown_search.dart';
import 'package:flutter/material.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:geocoding/geocoding.dart' as get_cord_address;
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location/location.dart';
import 'package:audioplayers/audioplayers.dart' show AudioCache;
import 'package:provider/provider.dart';
import '../../controller/dash_board_controller.dart';
import '../../controller/new_ride_controller.dart';
import '../../model/ride_model.dart';
import '../../model/user_model.dart';
import '../../themes/custom_alert_dialog.dart';
import '../../widget/StarRating.dart';
import '../complaint/add_complaint_screen.dart';
import '../completed/trip_history_screen.dart';
import '../dash_board.dart';
import '../review_screens/add_review_screen.dart';
import '../route_view_screen/route_view_screen.dart';
import 'package:firebase_database/firebase_database.dart';

class CreateRideScreen extends StatefulWidget {
  const CreateRideScreen({Key? key}) : super(key: key);

  @override
  State<CreateRideScreen> createState() => _CreateRideScreenState();
}

class _CreateRideScreenState extends State<CreateRideScreen> {
  final CameraPosition _kInitialPosition = const CameraPosition(
      target: LatLng(19.018255973653343, 72.84793849278007),
      zoom: 11.0,
      tilt: 0,
      bearing: 0);
  final resonController = TextEditingController();
  final TextEditingController departureController = TextEditingController();
  final TextEditingController destinationController = TextEditingController();
  // final audioplayers.AudioCache _audioCache = audioplayers.AudioCache();
  final controller = Get.put(CreateRideController());
  final myKey = GlobalKey<DropdownSearchState<CustomerData>>();
  GoogleMapController? _controller;
  final Location currentLocation = Location();

  final Map<String, Marker> _markers = {};

  BitmapDescriptor? departureIcon;
  BitmapDescriptor? destinationIcon;
  BitmapDescriptor? taxiIcon;
  BitmapDescriptor? stopIcon;

  LatLng? departureLatLong;
  LatLng? destinationLatLong;

  Map<PolylineId, Polyline> polyLines = {};
  PolylinePoints polylinePoints = PolylinePoints();

  static get audioplayers => "";

  @override
  void initState() {
    getCurrentLocation(true);
    super.initState();
    //   String? token = await FirebaseMessaging.instance.getToken();
    // if (token != null) {
    //   FirebaseDatabase.instance.reference().child('drivers/$userId').set({'fcmToken': token});
    // }
  }

  Widget build(BuildContext context) {
    return Column(children: [
      AppBar(
        backgroundColor: Colors.black,
        leading: IconButton(
          icon: Icon(
            Icons.menu,
            color: Colors.white,
          ),
          onPressed: () {
            // Open the drawer
            Scaffold.of(context).openDrawer();
          },
        ),
        title: Row(
          children: [
            Text(
              'Driver Status is ',
              style: TextStyle(
                color: Colors.white,
                // Add other styling properties if needed
              ),
            ),
            Switch(
              value: controller.isActive.value,
              activeColor: Colors.limeAccent,
              inactiveThumbColor: Colors.red,
              onChanged: (value) {
                setState(() {
                  controller.isActive.value = value;
                });

                // Change the text based on the Switch state
                String statusText = value ? 'Online' : 'Offline';

                Map<String, dynamic> bodyParams = {
                  'id_driver': Preferences.getInt(Preferences.userId),
                  'online': controller.isActive.value ? 'yes' : 'no',
                };

                controller.changeOnlineStatus(bodyParams).then((value) {
                  print('Response from server: $value');
                  if (value != null) {
                    if (value['success'] == 'success') {
                      UserModel userModel = Constant.getUserData();
                      userModel.userData!.online = value['data']['online'];
                      Preferences.setString(
                          Preferences.user, jsonEncode(userModel.toJson()));
                      controller.getUserData();
                      ShowToastDialog.showToast('Driver is $statusText');
                    } else {
                      ShowToastDialog.showToast(value['error']);
                      print('Failed to change status: ${value['error']}');
                    }
                  }
                });
              },
            ),
          ],
        ),
      ),
      Expanded(
        child: Stack(children: [
          GoogleMap(
            zoomControlsEnabled: false,
            myLocationButtonEnabled: true,
            padding: const EdgeInsets.only(
              top: 8.0,
            ),
            initialCameraPosition: _kInitialPosition,
            onMapCreated: (GoogleMapController controller) async {
              _controller = controller;
              LocationData location = await currentLocation.getLocation();
              LatLng initialLatLng =
                  LatLng(location.latitude ?? 0.0, location.longitude ?? 0.0);
              _controller!
                  .moveCamera(CameraUpdate.newLatLngZoom(initialLatLng, 14));
            },
            polylines: Set<Polyline>.of(polyLines.values),
            myLocationEnabled: true,
            markers: _markers.values.toSet(),
          ),
          GetX<NewRideController>(
            init: NewRideController(),
            builder: (controller) {
              List<RideData> newRides = controller.rideList
                  .where((ride) => ride.statut == 'new')
                  .toList();
              void playNotificationSound() {
                // _audioCache.play('notification.mp3'); // Replace with the actual sound file path
              }
              return Scaffold(
                body: Stack(
                  children: [
                    // GoogleMap as background
                    GoogleMap(
                      padding: const EdgeInsets.only(
                        top: 18.0,
                      ),
                      initialCameraPosition: _kInitialPosition,
                      onMapCreated: (GoogleMapController controller) async {
                        // Your map-related code here
                      },
                      polylines: Set<Polyline>.of(polyLines.values),
                      markers: _markers.values.toSet(),
                    ),
                    Positioned(
                      top: 0,
                      left: 0,
                      right: 0,
                      bottom: 0,
                      child: Container(
                        color: Colors.transparent,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (double.parse(
                                    controller.totalEarn.value.toString()) <
                                double.parse(Constant.minimumWalletBalance!))
                              Container(
                                padding: const EdgeInsets.all(5),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(10),
                                  color: Colors.limeAccent,
                                ),
                                child: Text(
                                  "Your wallet balance must be".tr +
                                      Constant().amountShow(
                                          amount: Constant.minimumWalletBalance!
                                              .toString()) +
                                      "to get a ride.".tr,
                                ),
                              ),
                            // Use Flexible instead of Expanded
                            Flexible(
                              child: newRides.isEmpty
                                  ? Container()
                                  : ListView.builder(
                                      itemCount: newRides.length,
                                      shrinkWrap: true,
                                      itemBuilder: (context, index) {
                                        return newRideWidgets(context,
                                            newRides[index], controller);
                                      },
                                    ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          )
        ]),
      )
    ]);
  }

  @override
  void dispose() {
    super.dispose();
  }

  void getCurrentLocation(bool isDepartureSet) async {
    if (isDepartureSet) {
      LocationData location = await currentLocation.getLocation();
      List<get_cord_address.Placemark> placeMarks =
          await get_cord_address.placemarkFromCoordinates(
              location.latitude ?? 0.0, location.longitude ?? 0.0);

      final address = (placeMarks.first.subLocality!.isEmpty
              ? ''
              : "${placeMarks.first.subLocality}, ") +
          (placeMarks.first.street!.isEmpty
              ? ''
              : "${placeMarks.first.street}, ") +
          (placeMarks.first.name!.isEmpty ? '' : "${placeMarks.first.name}, ") +
          (placeMarks.first.subAdministrativeArea!.isEmpty
              ? ''
              : "${placeMarks.first.subAdministrativeArea}, ") +
          (placeMarks.first.administrativeArea!.isEmpty
              ? ''
              : "${placeMarks.first.administrativeArea}, ") +
          (placeMarks.first.country!.isEmpty
              ? ''
              : "${placeMarks.first.country}, ") +
          (placeMarks.first.postalCode!.isEmpty
              ? ''
              : "${placeMarks.first.postalCode}, ");
      departureController.text = address;
      setState(() {
        setDepartureMarker(
            LatLng(location.latitude ?? 0.0, location.longitude ?? 0.0));
      });
    }
  }

  // @override
  // Widget build(BuildContext context) {
  //   return Scaffold(
  //     // floatingActionButton: FloatingActionButton(
  //     //   onPressed: (){
  //     //     Get.to(PaymentSelectionScreen());
  //     //   },
  //     // ),
  //     backgroundColor: ConstantColors.background,
  //     body: Stack(
  //       children: [
  //         GoogleMap(
  //           zoomControlsEnabled: true,
  //           myLocationButtonEnabled: true,
  //           padding: const EdgeInsets.only(
  //             top: 18.0,
  //           ),
  //           initialCameraPosition: _kInitialPosition,
  //           onMapCreated: (GoogleMapController controller) async {
  //             _controller = controller;
  //             LocationData location = await currentLocation.getLocation();
  //             _controller!.moveCamera(CameraUpdate.newLatLngZoom(
  //                 LatLng(location.latitude ?? 0.0, location.longitude ?? 0.0),
  //                 14));
  //           },
  //           polylines: Set<Polyline>.of(polyLines.values),
  //           myLocationEnabled: true,
  //           markers: _markers.values.toSet(),
  //         ),
  //         Column(
  //           crossAxisAlignment: CrossAxisAlignment.start,
  //           children: [
  //             Padding(
  //               padding: const EdgeInsets.only(top: 20),
  //               child: ElevatedButton(
  //                 onPressed: () {
  //                   Get.back();
  //                 },
  //                 style: ElevatedButton.styleFrom(
  //                   shape: const CircleBorder(),
  //                   backgroundColor: Colors.white,
  //                   padding: const EdgeInsets.fromLTRB(12, 2, 2, 2),
  //                 ),
  //                 child: Icon(
  //                   Icons.arrow_back_ios,
  //                   color: Colors.black,
  //                 ),
  //               ),
  //             ),
  //             Padding(
  //               padding:
  //               const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
  //               child: Container(
  //                 decoration: BoxDecoration(
  //                     borderRadius: BorderRadius.circular(10),
  //                     color: Colors.white),
  //                 child: Padding(
  //                   padding: const EdgeInsets.symmetric(
  //                       vertical: 8.0, horizontal: 10),
  //                   child: Column(
  //                     children: [
  //                       Builder(builder: (context) {
  //                         return Padding(
  //                           padding: const EdgeInsets.symmetric(horizontal: 00),
  //                           child: Row(
  //                             children: [
  //                               Image.asset(
  //                                 "assets/icons/location.png",
  //                                 height: 25,
  //                                 width: 25,
  //                               ),
  //                               Expanded(
  //                                 child: InkWell(
  //                                   onTap: () async {
  //                                     await controller
  //                                         .placeSelectAPI(context)
  //                                         .then((value) {
  //                                       if (value != null) {
  //                                         departureController.text = value
  //                                             .result.formattedAddress
  //                                             .toString();
  //                                         setDepartureMarker(LatLng(
  //                                             value.result.geometry!.location
  //                                                 .lat,
  //                                             value.result.geometry!.location
  //                                                 .lng));
  //                                       }
  //                                     });
  //                                   },
  //                                   child: buildTextField(
  //                                     title: "Departure".tr,
  //                                     textController: departureController,
  //                                   ),
  //                                 ),
  //                               ),
  //                               IconButton(
  //                                 onPressed: () {
  //                                   getCurrentLocation(true);
  //                                 },
  //                                 autofocus: false,
  //                                 icon: const Icon(
  //                                   Icons.my_location_outlined,
  //                                   size: 18,
  //                                 ),
  //                               ),
  //                             ],
  //                           ),
  //                         );
  //                       }),
  //                       ReorderableListView(
  //                         shrinkWrap: true,
  //                         physics: const NeverScrollableScrollPhysics(),
  //                         children: <Widget>[
  //                           for (int index = 0;
  //                           index < controller.multiStopListNew.length;
  //                           index += 1)
  //                             Container(
  //                               key: ValueKey(
  //                                   controller.multiStopListNew[index]),
  //                               child: Column(
  //                                 children: [
  //                                   const Divider(),
  //                                   InkWell(
  //                                       onTap: () async {
  //                                         await controller
  //                                             .placeSelectAPI(context)
  //                                             .then((value) {
  //                                           if (value != null) {
  //                                             controller.multiStopListNew[index]
  //                                                 .editingController.text =
  //                                                 value.result.formattedAddress
  //                                                     .toString();
  //                                             controller.multiStopListNew[index]
  //                                                 .latitude =
  //                                                 value.result.geometry!
  //                                                     .location.lat
  //                                                     .toString();
  //                                             controller.multiStopListNew[index]
  //                                                 .longitude =
  //                                                 value.result.geometry!
  //                                                     .location.lng
  //                                                     .toString();
  //                                             setStopMarker(
  //                                                 LatLng(
  //                                                     value.result.geometry!
  //                                                         .location.lat,
  //                                                     value.result.geometry!
  //                                                         .location.lng),
  //                                                 index);
  //                                           }
  //                                         });
  //                                       },
  //                                       child: Row(
  //                                           crossAxisAlignment:
  //                                           CrossAxisAlignment.center,
  //                                           children: [
  //                                             Text(
  //                                               String.fromCharCode(index + 65),
  //                                               style: TextStyle(
  //                                                   fontSize: 16,
  //                                                   color: ConstantColors
  //                                                       .hintTextColor),
  //                                             ),
  //                                             const SizedBox(
  //                                               width: 5,
  //                                             ),
  //                                             Expanded(
  //                                               child: buildTextField(
  //                                                 title:
  //                                                 "Where do you want to stop ?"
  //                                                     .tr,
  //                                                 textController: controller
  //                                                     .multiStopListNew[index]
  //                                                     .editingController,
  //                                               ),
  //                                             ),
  //                                             const SizedBox(
  //                                               width: 5,
  //                                             ),
  //                                             InkWell(
  //                                               onTap: () {
  //                                                 controller.removeStops(index);
  //                                                 _markers
  //                                                     .remove("Stop $index");
  //                                                 getDirections();
  //                                               },
  //                                               child: Icon(
  //                                                 Icons.close,
  //                                                 size: 25,
  //                                                 color: ConstantColors
  //                                                     .hintTextColor,
  //                                               ),
  //                                             )
  //                                           ])),
  //                                 ],
  //                               ),
  //                             ),
  //                         ],
  //                         onReorder: (int oldIndex, int newIndex) {
  //                           setState(() {
  //                             if (oldIndex < newIndex) {
  //                               newIndex -= 1;
  //                             }
  //                             final AddStopModel item = controller
  //                                 .multiStopListNew
  //                                 .removeAt(oldIndex);
  //                             controller.multiStopListNew
  //                                 .insert(newIndex, item);
  //                           });
  //                         },
  //                       ),
  //                       Row(
  //                         children: [
  //                           Image.asset(
  //                             "assets/icons/dropoff.png",
  //                             height: 25,
  //                             width: 25,
  //                           ),
  //                           Expanded(
  //                             child: InkWell(
  //                               onTap: () async {
  //                                 await controller
  //                                     .placeSelectAPI(context)
  //                                     .then((value) {
  //                                   if (value != null) {
  //                                     destinationController.text = value
  //                                         .result.formattedAddress
  //                                         .toString();
  //                                     setDestinationMarker(LatLng(
  //                                         value.result.geometry!.location.lat,
  //                                         value.result.geometry!.location.lng));
  //                                   }
  //                                 });
  //                               },
  //                               child: buildTextField(
  //                                 title: "Where do you want to stop ?".tr,
  //                                 textController: destinationController,
  //                               ),
  //                             ),
  //                           ),
  //                         ],
  //                       ),
  //                       const Divider(),
  //                       InkWell(
  //                         onTap: () {
  //                           controller.addStops();
  //                         },
  //                         child: Row(
  //                           children: [
  //                             Icon(
  //                               Icons.add_circle,
  //                               color: ConstantColors.hintTextColor,
  //                             ),
  //                             const SizedBox(
  //                               width: 5,
  //                             ),
  //                             Text(
  //                               'Add stop'.tr,
  //                               style: TextStyle(
  //                                   color: ConstantColors.hintTextColor,
  //                                   fontSize: 16),
  //                             ),
  //                           ],
  //                         ),
  //                       ),
  //                     ],
  //                   ),
  //                 ),
  //               ),
  //             ),
  //           ],
  //         )
  //       ],
  //     ),
  //   );
  // }

  setDepartureMarker(LatLng departure) {
    setState(() {
      _markers.remove("Departure");
      _markers['Departure'] = Marker(
        markerId: const MarkerId('Departure'),
        infoWindow: const InfoWindow(title: "Departure"),
        position: departure,
        icon: departureIcon!,
      );
      departureLatLong = departure;
      _controller!.animateCamera(CameraUpdate.newCameraPosition(CameraPosition(
          target: LatLng(departure.latitude, departure.longitude), zoom: 14)));

      // _controller?.animateCamera(CameraUpdate.newCameraPosition(CameraPosition(target: LatLng(departure.latitude, departure.longitude), zoom: 18)));
      if (departureLatLong != null && destinationLatLong != null) {
        getDirections();
        conformationBottomSheet(context);
      }
    });
  }

  setDestinationMarker(LatLng destination) {
    setState(() {
      _markers['Destination'] = Marker(
        markerId: const MarkerId('Destination'),
        infoWindow: const InfoWindow(title: "Destination"),
        position: destination,
        icon: destinationIcon!,
      );
      destinationLatLong = destination;

      if (departureLatLong != null && destinationLatLong != null) {
        getDirections();
        conformationBottomSheet(context);
      }
    });
  }

  setStopMarker(LatLng destination, int index) {
    setState(() {
      _markers['Stop $index'] = Marker(
        markerId: MarkerId('Stop $index'),
        infoWindow:
            InfoWindow(title: "Stop ${String.fromCharCode(index + 65)}"),
        position: destination,
        icon: stopIcon!,
      ); //BitmapDescriptor.fromBytes(unit8List));
      // destinationLatLong = destination;

      if (departureLatLong != null && destinationLatLong != null) {
        getDirections();
        conformationBottomSheet(context);
      }
    });
  }

  Widget buildTextField(
      {required title, required TextEditingController textController}) {
    return Padding(
      padding: const EdgeInsets.only(left: 8.0),
      child: TextField(
        controller: textController,
        textInputAction: TextInputAction.done,
        style: TextStyle(color: ConstantColors.titleTextColor),
        decoration: InputDecoration(
          hintText: title,
          border: InputBorder.none,
          focusedBorder: InputBorder.none,
          enabled: false,
        ),
      ),
    );
  }

  getDirections() async {
    List<LatLng> polylineCoordinates = [];

    PolylineResult result = await polylinePoints.getRouteBetweenCoordinates(
      Constant.kGoogleApiKey.toString(),
      PointLatLng(departureLatLong!.latitude, departureLatLong!.longitude),
      PointLatLng(destinationLatLong!.latitude, destinationLatLong!.longitude),
      optimizeWaypoints: true,
      travelMode: TravelMode.driving,
    );

    if (result.points.isNotEmpty) {
      for (var point in result.points) {
        polylineCoordinates.add(LatLng(point.latitude, point.longitude));
      }
    }

    addPolyLine(polylineCoordinates);
  }

  addPolyLine(List<LatLng> polylineCoordinates) {
    PolylineId id = const PolylineId("poly");
    Polyline polyline = Polyline(
      polylineId: id,
      color: ConstantColors.primary,
      points: polylineCoordinates,
      width: 4,
      geodesic: true,
    );
    polyLines[id] = polyline;
    setState(() {});
  }

  conformationBottomSheet(BuildContext context) {
    return showModalBottomSheet(
        shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.only(
                topRight: Radius.circular(15), topLeft: Radius.circular(15))),
        context: context,
        isDismissible: false,
        backgroundColor: Colors.transparent,
        builder: (context) {
          return StatefulBuilder(builder: (context, setState) {
            return Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 15.0, vertical: 20),
              child: Row(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    child: ButtonThem.buildIconButton(context,
                        icon: Icons.arrow_back_ios,
                        iconColor: Colors.black,
                        btnHeight: 40,
                        btnWidthRatio: 0.25,
                        title: "Back".tr,
                        btnColor: Colors.limeAccent,
                        txtColor: Colors.black, onPress: () {
                      Get.back();
                    }),
                  ),
                  Expanded(
                    child: ButtonThem.buildButton(context,
                        btnHeight: 40,
                        title: "Continue".tr,
                        btnColor: Colors.limeAccent,
                        txtColor: Colors.black, onPress: () async {
                      controller.checkBalance().then((value) {
                        if (value == true) {
                          controller.getDriverDetails().then((value) async {
                            if (value != null) {
                              await controller
                                  .getDurationDistance(
                                      departureLatLong!, destinationLatLong!)
                                  .then((durationValue) async {
                                if (durationValue != null) {
                                  if (Constant.distanceUnit == "KM") {
                                    controller.distance.value =
                                        durationValue['rows']
                                                .first['elements']
                                                .first['distance']['value'] /
                                            1000.00;
                                  } else {
                                    controller.distance.value =
                                        durationValue['rows']
                                                .first['elements']
                                                .first['distance']['value'] /
                                            1609.34;
                                  }

                                  controller.duration.value =
                                      durationValue['rows']
                                          .first['elements']
                                          .first['duration']['text'];
                                  Get.back();
                                  tripOptionBottomSheet(context);
                                }
                              });
                            } else {
                              ShowToastDialog.showToast(
                                  'Your document is not verified by admin'.tr);
                            }
                          });
                        } else {
                          ShowToastDialog.showToast(
                              "Your wallet balance must be".tr +
                                  Constant().amountShow(
                                      amount: Constant.minimumWalletBalance!
                                          .toString()) +
                                  'to book ride.'.tr);
                        }
                      });
                    }),
                  ),
                ],
              ),
            );
          });
        });
  }

  final passengerFirstNameController = TextEditingController();
  final passengerLastNameController = TextEditingController();
  final passengerEmailController = TextEditingController();
  final passengerNumberController = TextEditingController();
  final passengerController = TextEditingController();

  tripOptionBottomSheet(BuildContext context) {
    return showModalBottomSheet(
        context: context,
        isDismissible: false,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (context) {
          return Container(
            decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.all(Radius.circular(15))),
            margin: const EdgeInsets.all(10),
            child: StatefulBuilder(builder: (context, setState) {
              return Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 15.0, vertical: 20),
                child: Padding(
                  padding: MediaQuery.of(context).viewInsets,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              "Customer Info".tr,
                              style: const TextStyle(
                                  fontSize: 18, color: Colors.black),
                            ),
                            Visibility(
                              visible: controller.createUser.value,
                              child: InkWell(
                                onTap: () {
                                  controller.createUser.value = false;
                                  passengerFirstNameController.clear();
                                  passengerLastNameController.clear();
                                  passengerEmailController.clear();
                                  passengerNumberController.clear();
                                  passengerController.clear();
                                },
                                child: Text(
                                  "Select user".tr,
                                  style: const TextStyle(
                                      fontSize: 16, color: Colors.black),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Visibility(
                        visible: !controller.createUser.value,
                        child: Column(
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Padding(
                                    padding: const EdgeInsets.all(8.0),
                                    child: DropdownSearch<CustomerData>(
                                      key: myKey,

                                      popupProps: PopupProps.dialog(
                                        showSearchBox: true,
                                        showSelectedItems: true,
                                        searchFieldProps: TextFieldProps(
                                          cursorColor: ConstantColors.primary,
                                          decoration: InputDecoration(
                                            contentPadding:
                                                const EdgeInsets.fromLTRB(
                                                    8, 0, 8, 0),
                                            border: const OutlineInputBorder(
                                              borderSide: BorderSide(
                                                  color: Colors.grey,
                                                  width: 1.0),
                                            ),
                                            hintText: "Search user".tr,
                                          ),
                                        ),
                                      ),
                                      dropdownDecoratorProps:
                                          DropDownDecoratorProps(
                                        dropdownSearchDecoration:
                                            InputDecoration(
                                          contentPadding:
                                              const EdgeInsets.fromLTRB(
                                                  8, 0, 8, 0),
                                          border: const OutlineInputBorder(
                                            borderSide: BorderSide(
                                                color: Colors.black,
                                                width: 1.0),
                                          ),
                                          hintText: "Select user".tr,
                                        ),
                                      ),

                                      compareFn: (item1, item2) =>
                                          item1.fullName() == item2.fullName(),
                                      itemAsString: (CustomerData u) =>
                                          u.userAsString(),
                                      onChanged: (CustomerData? value) async {
                                        controller.selectedUser = value;
                                        passengerFirstNameController.text =
                                            value!.prenom!;
                                        passengerLastNameController.text =
                                            value.nom!;
                                        passengerEmailController.text =
                                            value.email!;
                                        passengerNumberController.text =
                                            value.phone!;
                                      },
                                      items: controller.userList,
                                      selectedItem: controller.selectedUser,

                                      // filterFn: (user, filter) =>
                                      //     user.userFilterByCreationDate(filter),
                                    ),

                                    // DropdownButtonFormField(
                                    //     isExpanded: true,
                                    //     decoration: const InputDecoration(
                                    //       contentPadding:
                                    //           EdgeInsets.symmetric(
                                    //               vertical: 11,
                                    //               horizontal: 8),
                                    //       focusedBorder: OutlineInputBorder(
                                    //         borderSide: BorderSide(
                                    //             color: Colors.grey,
                                    //             width: 1.0),
                                    //       ),
                                    //       enabledBorder: OutlineInputBorder(
                                    //         borderSide: BorderSide(
                                    //             color: Colors.grey,
                                    //             width: 1.0),
                                    //       ),
                                    //       errorBorder: OutlineInputBorder(
                                    //         borderSide: BorderSide(
                                    //             color: Colors.grey,
                                    //             width: 1.0),
                                    //       ),
                                    //       border: OutlineInputBorder(
                                    //         borderSide: BorderSide(
                                    //             color: Colors.grey,
                                    //             width: 1.0),
                                    //       ),
                                    //       isDense: true,
                                    //     ),
                                    //     onChanged: (CustomerData? value) {
                                    //       controller.selectedUser = value;
                                    //       passengerFirstNameController
                                    //           .text = value!.nom!;
                                    //       passengerLastNameController.text =
                                    //           value.prenom!;
                                    //       passengerEmailController.text =
                                    //           value.email!;
                                    //       passengerNumberController.text =
                                    //           value.phone!;
                                    //     },
                                    //     hint: const Text("Select user"),
                                    //     items:
                                    //         controller.userList.map((item) {
                                    //       return DropdownMenuItem(
                                    //         value: item,
                                    //         child: Text(
                                    //           "${item.nom} ${item.prenom}",
                                    //         ),
                                    //       );
                                    //     }).toList()),
                                  ),
                                ),
                                Expanded(
                                  child: Padding(
                                    padding: const EdgeInsets.all(8.0),
                                    child: TextField(
                                      controller: passengerController,
                                      keyboardType: TextInputType.number,
                                      decoration: InputDecoration(
                                        contentPadding: const EdgeInsets.all(8),
                                        focusedBorder: const OutlineInputBorder(
                                          borderSide: BorderSide(
                                              color: Colors.grey, width: 1.0),
                                        ),
                                        enabledBorder: const OutlineInputBorder(
                                          borderSide: BorderSide(
                                              color: Colors.grey, width: 1.0),
                                        ),
                                        hintText: 'No. of passenger'.tr,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(
                              height: 10,
                            ),
                            InkWell(
                              onTap: () {
                                controller.selectedUser = null;
                                controller.createUser.value = true;
                                passengerFirstNameController.clear();
                                passengerLastNameController.clear();
                                passengerEmailController.clear();
                                passengerNumberController.clear();
                                passengerController.clear();
                              },
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.add_circle,
                                    color: ConstantColors.hintTextColor,
                                  ),
                                  const SizedBox(
                                    width: 5,
                                  ),
                                  Text(
                                    'Create user'.tr,
                                    style: TextStyle(
                                        color: ConstantColors.hintTextColor,
                                        fontSize: 16),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(
                              height: 10,
                            ),
                          ],
                        ),
                      ),
                      Visibility(
                        visible: controller.createUser.value,
                        child: Column(
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Padding(
                                    padding: const EdgeInsets.all(8.0),
                                    child: TextField(
                                      controller: passengerFirstNameController,
                                      keyboardType: TextInputType.name,
                                      decoration: InputDecoration(
                                        contentPadding: const EdgeInsets.all(8),
                                        focusedBorder: const OutlineInputBorder(
                                          borderSide: BorderSide(
                                              color: Colors.grey, width: 1.0),
                                        ),
                                        enabledBorder: const OutlineInputBorder(
                                          borderSide: BorderSide(
                                              color: Colors.grey, width: 1.0),
                                        ),
                                        hintText: 'First name'.tr,
                                      ),
                                    ),
                                  ),
                                ),
                                Expanded(
                                  child: Padding(
                                    padding: const EdgeInsets.all(8.0),
                                    child: TextField(
                                      controller: passengerLastNameController,
                                      keyboardType: TextInputType.name,
                                      decoration: InputDecoration(
                                        contentPadding: const EdgeInsets.all(8),
                                        focusedBorder: const OutlineInputBorder(
                                          borderSide: BorderSide(
                                              color: Colors.grey, width: 1.0),
                                        ),
                                        enabledBorder: const OutlineInputBorder(
                                          borderSide: BorderSide(
                                              color: Colors.grey, width: 1.0),
                                        ),
                                        hintText: 'Last name'.tr,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: TextField(
                                controller: passengerEmailController,
                                keyboardType: TextInputType.emailAddress,
                                decoration: InputDecoration(
                                  contentPadding: const EdgeInsets.all(8),
                                  focusedBorder: const OutlineInputBorder(
                                    borderSide: BorderSide(
                                        color: Colors.grey, width: 1.0),
                                  ),
                                  enabledBorder: const OutlineInputBorder(
                                    borderSide: BorderSide(
                                        color: Colors.grey, width: 1.0),
                                  ),
                                  hintText: 'email'.tr,
                                ),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: TextField(
                                controller: passengerNumberController,
                                keyboardType: TextInputType.number,
                                decoration: InputDecoration(
                                  contentPadding: const EdgeInsets.all(8),
                                  focusedBorder: const OutlineInputBorder(
                                    borderSide: BorderSide(
                                        color: Colors.grey, width: 1.0),
                                  ),
                                  enabledBorder: const OutlineInputBorder(
                                    borderSide: BorderSide(
                                        color: Colors.grey, width: 1.0),
                                  ),
                                  hintText: 'Phone number'.tr,
                                ),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: TextField(
                                controller: passengerController,
                                keyboardType: TextInputType.number,
                                decoration: InputDecoration(
                                  contentPadding: const EdgeInsets.all(8),
                                  focusedBorder: const OutlineInputBorder(
                                    borderSide: BorderSide(
                                        color: Colors.grey, width: 1.0),
                                  ),
                                  enabledBorder: const OutlineInputBorder(
                                    borderSide: BorderSide(
                                        color: Colors.grey, width: 1.0),
                                  ),
                                  hintText: 'No. of passenger'.tr,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(top: 10),
                        child: Row(
                          children: [
                            Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 10),
                              child: ButtonThem.buildIconButton(context,
                                  icon: Icons.arrow_back_ios,
                                  iconColor: Colors.black,
                                  btnHeight: 40,
                                  btnWidthRatio: 0.25,
                                  title: "Back".tr,
                                  btnColor: Colors.limeAccent,
                                  txtColor: Colors.black, onPress: () {
                                Get.back();
                              }),
                            ),
                            Expanded(
                              child: ButtonThem.buildButton(context,
                                  btnHeight: 40,
                                  title: "book_now".tr,
                                  btnColor: Colors.limeAccent,
                                  txtColor: Colors.black, onPress: () async {
                                if ((passengerFirstNameController.text.isEmpty ||
                                        passengerLastNameController
                                            .text.isEmpty ||
                                        passengerNumberController
                                            .text.isEmpty ||
                                        passengerEmailController
                                            .text.isEmpty) &&
                                    controller.selectedUser == null) {
                                  ShowToastDialog.showToast(
                                      "Please Enter Details".tr);
                                } else if (passengerController.text.isEmpty) {
                                  ShowToastDialog.showToast(
                                      "Please Enter Details".tr);
                                } else {
                                  double cout = 0.0;

                                  if (controller.distance.value >
                                      double.parse(controller.vehicleData!
                                          .minimumDeliveryChargesWithin!)) {
                                    cout = (controller.distance.value *
                                            double.parse(controller
                                                .vehicleData!.deliveryCharges!))
                                        .toDouble();
                                  } else {
                                    cout = double.parse(controller
                                        .vehicleData!.minimumDeliveryCharges
                                        .toString());
                                  }
                                  for (var i = 0;
                                      i < Constant.taxList.length;
                                      i++) {
                                    if (Constant.taxList[i].statut == 'yes') {
                                      if (Constant.taxList[i].type == "Fixed") {
                                        controller.taxAmount.value +=
                                            double.parse(Constant
                                                .taxList[i].value
                                                .toString());
                                      } else {
                                        controller.taxAmount.value += (cout *
                                                double.parse(Constant
                                                    .taxList[i].value!
                                                    .toString())) /
                                            100;
                                      }
                                    }
                                  }
                                  Get.back();
                                  conformDataBottomSheet(context, cout);
                                }
                              }),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          );
        });
  }

  conformDataBottomSheet(BuildContext context, double tripPrice) {
    return showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        isDismissible: false,
        backgroundColor: Colors.transparent,
        builder: (context) {
          return Container(
            decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.all(Radius.circular(15))),
            margin: const EdgeInsets.all(10),
            child: StatefulBuilder(builder: (context, setState) {
              return Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 15.0, vertical: 15),
                child: Obx(
                  () => Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 20.0),
                        child: Row(
                          children: [
                            Expanded(
                                child: buildDetails(
                                    title: "Cash".tr,
                                    value: 'Payment method'.tr)),
                            const SizedBox(
                              width: 10,
                            ),
                            Expanded(
                                child: buildDetails(
                                    title:
                                        "${controller.distance.value.toStringAsFixed(int.parse(Constant.decimal!))}${Constant.distanceUnit}",
                                    value: 'Distance'.tr)),
                            const SizedBox(
                              width: 10,
                            ),
                            Expanded(
                                child: buildDetails(
                                    title: controller.duration.value,
                                    value: 'Duration'.tr)),
                            const SizedBox(
                              width: 10,
                            ),
                            Expanded(
                                child: buildDetails(
                                    title: Constant().amountShow(
                                        amount: tripPrice.toString()),
                                    value: 'Trip Price'.tr,
                                    txtColor: Colors.black)),
                          ],
                        ),
                      ),
                      ListView.builder(
                        itemCount: Constant.taxList.length,
                        shrinkWrap: true,
                        padding: EdgeInsets.zero,
                        physics: const NeverScrollableScrollPhysics(),
                        itemBuilder: (context, index) {
                          TaxModel taxModel = Constant.taxList[index];
                          return ListTile(
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 0, vertical: 0),
                            title: Text(
                              '${taxModel.libelle.toString()} (${taxModel.type == "Fixed" ? Constant().amountShow(amount: taxModel.value) : "${taxModel.value}%"})',
                              style: TextStyle(
                                  letterSpacing: 1.0,
                                  color: ConstantColors.subTitleTextColor,
                                  fontWeight: FontWeight.w600),
                            ),
                            trailing: Text(
                                Constant().amountShow(
                                    amount: controller
                                        .calculateTax(
                                            taxModel: taxModel,
                                            tripPrice: tripPrice)
                                        .toString()),
                                style: TextStyle(
                                    letterSpacing: 1.0,
                                    color: ConstantColors.subTitleTextColor,
                                    fontWeight: FontWeight.w800)),
                          );
                        },
                      ),
                      const SizedBox(
                        height: 10,
                      ),
                      Divider(
                        color: Colors.grey.shade700,
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text("Total amount:".tr,
                              style: TextStyle(
                                  letterSpacing: 1.0,
                                  color: ConstantColors.subTitleTextColor,
                                  fontWeight: FontWeight.w800)),
                          Text(
                              Constant().amountShow(
                                  amount:
                                      (tripPrice + controller.taxAmount.value)
                                          .toString()),
                              style: TextStyle(
                                  letterSpacing: 1.0,
                                  color: ConstantColors.subTitleTextColor,
                                  fontWeight: FontWeight.w800))
                        ],
                      ),
                      Divider(
                        color: Colors.grey.shade700,
                      ),
                      Row(
                        children: [
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 10),
                            child: ButtonThem.buildIconButton(context,
                                icon: Icons.arrow_back_ios,
                                iconColor: Colors.black,
                                btnHeight: 40,
                                btnWidthRatio: 0.25,
                                title: "Back".tr,
                                btnColor: Colors.limeAccent,
                                txtColor: Colors.black, onPress: () async {
                              Get.back();
                              tripOptionBottomSheet(context);
                            }),
                          ),
                          Expanded(
                            child: ButtonThem.buildButton(context,
                                btnHeight: 40,
                                title: "book_now".tr,
                                btnColor: Colors.limeAccent,
                                txtColor: Colors.black, onPress: () {
                              List stopsList = [];
                              for (var i = 0;
                                  i < controller.multiStopListNew.length;
                                  i++) {
                                stopsList.add({
                                  "latitude": controller
                                      .multiStopListNew[i].latitude
                                      .toString(),
                                  "longitude": controller
                                      .multiStopListNew[i].longitude
                                      .toString(),
                                  "location": controller.multiStopListNew[i]
                                      .editingController.text
                                      .toString()
                                });
                              }
                              Map<String, dynamic> bodyParams = {
                                'user_id': controller.selectedUser != null
                                    ? controller.selectedUser!.id!
                                    : DateTime.now().millisecondsSinceEpoch,
                                'lat1': departureLatLong!.latitude.toString(),
                                'lng1': departureLatLong!.longitude.toString(),
                                'lat2': destinationLatLong!.latitude.toString(),
                                'lng2':
                                    destinationLatLong!.longitude.toString(),
                                'cout': tripPrice.toString(),
                                'distance': controller.distance.toString(),
                                'distance_unit':
                                    Constant.distanceUnit.toString(),
                                'duree': controller.duration.toString(),
                                'id_conducteur':
                                    Preferences.getInt(Preferences.userId)
                                        .toString(),
                                'id_payment': controller.paymentMethodId.value,
                                'depart_name': departureController.text,
                                'destination_name': destinationController.text,
                                'stops': stopsList,
                                'place': '',
                                'number_poeple': passengerController.text,
                                'image': '',
                                'image_name': "",
                                'user_detail': {
                                  'name':
                                      "${passengerFirstNameController.text} ${passengerLastNameController.text}",
                                  'phone':
                                      passengerNumberController.text.toString(),
                                  'email':
                                      passengerEmailController.text.toString()
                                },
                                'ride_type': "driver",
                                'statut_round': 'no',
                                'trip_objective': "",
                                'age_children1': "",
                                'age_children2': "",
                                'age_children3': "",
                              };

                              controller.bookRide(bodyParams).then((value) {
                                if (value != null) {
                                  if (value['success'] == "success") {
                                    Get.back();
                                    getDirections();
                                    departureController.clear();
                                    destinationController.clear();
                                    polyLines = {};
                                    departureLatLong = null;
                                    destinationLatLong = null;

                                    passengerFirstNameController.clear();
                                    passengerLastNameController.clear();
                                    passengerEmailController.clear();
                                    passengerController.clear();
                                    passengerNumberController.clear();
                                    tripPrice = 0.0;
                                    _markers.clear();

                                    showDialog(
                                        context: context,
                                        builder: (BuildContext context) {
                                          return CustomDialogBox(
                                            text: "Ok".tr,
                                            title: "",
                                            descriptions:
                                                "Your booking is confirmed".tr,
                                            onPress: () {
                                              Get.back();
                                              Get.back();
                                            },
                                            img: Image.asset(
                                                'assets/images/green_checked.png'),
                                          );
                                        });
                                  }
                                }
                              });
                            }),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            }),
          );
        });
  }

  buildDetails({title, value, Color txtColor = Colors.black}) {
    return Container(
      height: 110,
      decoration: BoxDecoration(
          color: Colors.limeAccent, borderRadius: BorderRadius.circular(8)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Opacity(
            opacity: 0.9,
            child: Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: 15,
                  color: Colors.black,
                  fontWeight: FontWeight.w600),
            ),
          ),
          const SizedBox(
            height: 6,
          ),
          Opacity(
            opacity: 0.6,
            child: Text(
              value,
              textAlign: TextAlign.center,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }

  Widget newRideWidgets(
      BuildContext context, RideData data, NewRideController controller) {
    return InkWell(
      onTap: () async {
        if (data.statut == "completed") {
          var isDone = await Get.to(const TripHistoryScreen(), arguments: {
            "rideData": data,
          });
          if (isDone != null) {
            controller.getNewRide();
          }
        } else {
          var argumentData = {'type': data.statut, 'data': data};
          if (Constant.mapType == "inappmap") {
            Get.to(const RouteViewScreen(), arguments: argumentData);
          } else {
            Constant.redirectMap(
              latitude: double.parse(data
                  .latitudeArrivee!), //orderModel.destinationLocationLAtLng!.latitude!,
              longLatitude: double.parse(data
                  .longitudeArrivee!), //orderModel.destinationLocationLAtLng!.longitude!,
              name: data.destinationName!,
            ); //orderModel.destinationLocationName.toString());
          }
        }
      },
      child: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 8.0,
              vertical: 10,
            ),
            child: Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.all(Radius.circular(15.0)),
              ),
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12.0, vertical: 12),
                child: Column(
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Column(
                          children: [
                            Image.asset(
                              "assets/icons/location.png",
                              height: 20,
                            ),
                            Image.asset(
                              "assets/icons/line.png",
                              height: 30,
                            ),
                          ],
                        ),
                        const SizedBox(
                          width: 5,
                        ),
                        Expanded(
                          child: Text(
                            data.departName.toString(),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const Divider(),
                      ],
                    ),
                    ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: data.stops!.length,
                        itemBuilder: (context, int index) {
                          return Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Column(
                                children: [
                                  Text(
                                    String.fromCharCode(index + 65),
                                    style: const TextStyle(
                                      fontSize: 16,
                                    ),
                                  ),
                                  Image.asset(
                                    "assets/icons/line.png",
                                    height: 30,
                                    color: ConstantColors.hintTextColor,
                                  ),
                                ],
                              ),
                              const SizedBox(
                                width: 5,
                              ),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      data.stops![index].location.toString(),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const Divider(),
                                  ],
                                ),
                              ),
                            ],
                          );
                        }),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        Image.asset(
                          "assets/icons/round.png",
                          height: 18,
                        ),
                        const SizedBox(
                          width: 5,
                        ),
                        Expanded(
                          child: Text(
                            data.destinationName.toString(),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),

                    // Row(
                    //   children: [
                    //     Image.asset(
                    //       "assets/icons/ic_pic_drop_location.png",
                    //       height: 60,
                    //     ),
                    //     Expanded(
                    //       child: Padding(
                    //         padding: const EdgeInsets.symmetric(horizontal: 10),
                    //         child: Column(
                    //           crossAxisAlignment: CrossAxisAlignment.start,
                    //           children: [
                    //             Text(
                    //               data.departName.toString(),
                    //               maxLines: 2,
                    //               overflow: TextOverflow.ellipsis,
                    //             ),
                    //             const Divider(),
                    //             Text(
                    //               data.destinationName.toString(),
                    //               maxLines: 2,
                    //               overflow: TextOverflow.ellipsis,
                    //             ),
                    //           ],
                    //         ),
                    //       ),
                    //     ),
                    //   ],
                    // ),
                    Padding(
                      padding: const EdgeInsets.only(top: 10),
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Expanded(
                              child: Padding(
                                padding: const EdgeInsets.only(left: 5.0),
                                child: Container(
                                  decoration: BoxDecoration(
                                      border: Border.all(
                                        color: Colors.black12,
                                      ),
                                      borderRadius: const BorderRadius.all(
                                          Radius.circular(10))),
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 18),
                                    child: Column(
                                      children: [
                                        Image.asset(
                                          'assets/icons/passenger.png',
                                          height: 22,
                                          width: 22,
                                          color: ConstantColors.yellow,
                                        ),
                                        Padding(
                                          padding:
                                              const EdgeInsets.only(top: 8.0),
                                          child: Text(
                                              " ${data.numberPoeple.toString()}",
                                              style: const TextStyle(
                                                  fontWeight: FontWeight.w800,
                                                  color: Colors.black54)),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            Expanded(
                              child: Padding(
                                padding: const EdgeInsets.only(left: 5.0),
                                child: Container(
                                  decoration: BoxDecoration(
                                      border: Border.all(
                                        color: Colors.black12,
                                      ),
                                      borderRadius: const BorderRadius.all(
                                          Radius.circular(10))),
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 20),
                                    child: Column(
                                      children: [
                                        Text(
                                          Constant.currency.toString(),
                                          style: TextStyle(
                                            color: ConstantColors.yellow,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 20,
                                          ),
                                        ),
                                        // Image.asset(
                                        //   'assets/icons/price.png',
                                        //   height: 22,
                                        //   width: 22,
                                        //   color: ConstantColors.yellow,
                                        // ),
                                        Text(
                                          Constant().amountShow(
                                              amount: data.montant.toString()),
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w800,
                                            color: Colors.black54,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            Expanded(
                              child: Padding(
                                padding: const EdgeInsets.only(left: 5.0),
                                child: Container(
                                  decoration: BoxDecoration(
                                      border: Border.all(
                                        color: Colors.black12,
                                      ),
                                      borderRadius: const BorderRadius.all(
                                          Radius.circular(10))),
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 18),
                                    child: Column(
                                      children: [
                                        Image.asset(
                                          'assets/icons/ic_distance.png',
                                          height: 22,
                                          width: 22,
                                          color: ConstantColors.yellow,
                                        ),
                                        Padding(
                                          padding:
                                              const EdgeInsets.only(top: 8.0),
                                          child: Text(
                                              "${double.parse(data.distance.toString()).toStringAsFixed(int.parse(Constant.decimal!))} ${Constant.distanceUnit}",
                                              style: const TextStyle(
                                                  fontWeight: FontWeight.w800,
                                                  color: Colors.black54)),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            Expanded(
                              child: Padding(
                                padding: const EdgeInsets.only(left: 5.0),
                                child: Container(
                                  decoration: BoxDecoration(
                                      border: Border.all(
                                        color: Colors.black12,
                                      ),
                                      borderRadius: const BorderRadius.all(
                                          Radius.circular(10))),
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 18),
                                    child: Column(
                                      children: [
                                        Image.asset(
                                          'assets/icons/time.png',
                                          height: 22,
                                          width: 22,
                                          color: ConstantColors.yellow,
                                        ),
                                        Padding(
                                          padding:
                                              const EdgeInsets.only(top: 8.0),
                                          child: TextScroll(
                                              data.duree.toString(),
                                              mode: TextScrollMode.bouncing,
                                              pauseBetween:
                                                  const Duration(seconds: 2),
                                              style: const TextStyle(
                                                  fontWeight: FontWeight.w800,
                                                  color: Colors.black54)),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(top: 10),
                      child: Row(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: CachedNetworkImage(
                              imageUrl: data.photoPath.toString(),
                              height: 80,
                              width: 80,
                              fit: BoxFit.cover,
                              placeholder: (context, url) => const Center(
                                  child: CircularProgressIndicator()),
                              errorWidget: (context, url, error) => Image.asset(
                                "assets/images/appIcon.png",
                              ),
                            ),
                          ),
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.only(left: 8.0),
                              child: data.rideType! == 'driver' &&
                                      data.existingUserId.toString() == "null"
                                  ? Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text('${data.userInfo!.name}',
                                            style: const TextStyle(
                                                color: Colors.black87,
                                                fontWeight: FontWeight.w600)),
                                        Text('${data.userInfo!.email}',
                                            style: const TextStyle(
                                                color: Colors.black87,
                                                fontWeight: FontWeight.w400)),
                                      ],
                                    )
                                  : Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                            '${data.prenom.toString()} ${data.nom.toString()}',
                                            style: const TextStyle(
                                                color: Colors.black87,
                                                fontWeight: FontWeight.w600)),
                                        StarRating(
                                            size: 18,
                                            rating: double.parse(
                                                data.moyenneDriver.toString()),
                                            color: ConstantColors.yellow),
                                      ],
                                    ),
                            ),
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              ElevatedButton(
                                onPressed: () {
                                  if (data.rideType! == 'driver' &&
                                      data.existingUserId.toString() ==
                                          "null") {
                                    Constant.makePhoneCall(
                                        data.userInfo!.phone.toString());
                                  } else {
                                    Constant.makePhoneCall(
                                        data.phone.toString());
                                  }
                                },
                                style: ElevatedButton.styleFrom(
                                  foregroundColor: Colors.blue,
                                  shape: const CircleBorder(),
                                  backgroundColor: Colors.blue,
                                  padding: const EdgeInsets.all(
                                      6), // <-- Splash color
                                ),
                                child: const Icon(
                                  Icons.call,
                                  color: Colors.white,
                                  size: 18,
                                ),
                              ),
                              Text(data.dateRetour.toString(),
                                  style: const TextStyle(
                                      color: Colors.black26,
                                      fontWeight: FontWeight.w600)),
                            ],
                          )
                        ],
                      ),
                    ),
                    // Visibility(
                    //   visible: data.statut == "completed",
                    //   child: Padding(
                    //     padding: const EdgeInsets.only(top: 8.0),
                    //     child: Row(
                    //       children: [
                    //         Expanded(
                    //             child: ButtonThem.buildButton(context,
                    //                 btnHeight: 40,
                    //                 title: data.statutPaiement == "yes" ? "paid".tr : "Not paid".tr,
                    //                 btnColor: data.statutPaiement == "yes" ? Colors.green : Colors.limeAccent,
                    //                 txtColor: Colors.white, onPress: () {
                    //                   // if (data.payment == "Cash") {
                    //                   //   controller.conformPaymentByCache(data.id.toString()).then((value) {
                    //                   //     if (value != null) {
                    //                   //       showDialog(
                    //                   //           context: context,
                    //                   //           builder: (BuildContext context) {
                    //                   //             return CustomDialogBox(
                    //                   //               title: "Payment by cash",
                    //                   //               descriptions: "Payment collected successfully",
                    //                   //               text: "Ok",
                    //                   //               onPress: () {
                    //                   //                 Get.back();
                    //                   //                 controller.getCompletedRide();
                    //                   //               },
                    //                   //               img: Image.asset('assets/images/green_checked.png'),
                    //                   //             );
                    //                   //           });
                    //                   //     }
                    //                   //   });
                    //                   // } else {}
                    //                 })),
                    //         if (data.existingUserId.toString() != "null")
                    //           Expanded(
                    //             child: Padding(
                    //                 padding: const EdgeInsets.only(left: 10),
                    //                 child: ButtonThem.buildBorderButton(
                    //                   context,
                    //                   title: 'add_review'.tr,
                    //                   btnWidthRatio: 0.8,
                    //                   btnHeight: 40,
                    //                   btnColor: Colors.white,
                    //                   txtColor: Colors.limeAccent,
                    //                   btnBorderColor: Colors.limeAccent,
                    //                   onPress: () async {
                    //                     Get.to(const AddReviewScreen(), arguments: {
                    //                       'rideData': data,
                    //                     });
                    //                   },
                    //                 )),
                    //           ),
                    //       ],
                    //     ),
                    //   ),
                    // ),
                    const SizedBox(
                      height: 10,
                    ),
                    Visibility(
                      visible: data.statut == "completed" &&
                          data.existingUserId.toString() != "null",
                      child: ButtonThem.buildBorderButton(
                        context,
                        title: 'Add Complaint'.tr,
                        btnHeight: 40,
                        btnColor: Colors.limeAccent,
                        txtColor: Colors.black,
                        btnBorderColor: Colors.limeAccent,
                        onPress: () async {
                          Get.to(AddComplaintScreen(), arguments: {
                            'rideData': data,
                          });
                        },
                      ),
                    ),

                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      child: Row(
                        children: [
                          Visibility(
                            visible: data.statut == "new" ||
                                    data.statut == "confirmed"
                                ? true
                                : false,
                            child: Expanded(
                              child: Padding(
                                padding: const EdgeInsets.only(bottom: 5),
                                child: ButtonThem.buildBorderButton(
                                  context,
                                  title: 'REJECT'.tr,
                                  btnHeight: 45,
                                  btnWidthRatio: 0.8,
                                  btnColor: Colors.limeAccent,
                                  txtColor: Colors.black.withOpacity(0.60),
                                  btnBorderColor:
                                      Colors.black.withOpacity(0.20),
                                  onPress: () async {
                                    buildShowBottomSheet(
                                        context, data, controller);
                                  },
                                ),
                              ),
                            ),
                          ),
                          Visibility(
                            visible: data.statut == "new" ? true : false,
                            child: Expanded(
                              child: Padding(
                                padding:
                                    const EdgeInsets.only(bottom: 5, left: 10),
                                child: ButtonThem.buildButton(
                                  context,
                                  title: 'ACCEPT'.tr,
                                  btnHeight: 45,
                                  btnWidthRatio: 0.8,
                                  btnColor: Colors.limeAccent,
                                  txtColor: Colors.black,
                                  onPress: () async {
                                    showDialog(
                                      barrierColor: Colors.black26,
                                      context: context,
                                      builder: (context) {
                                        return CustomAlertDialog(
                                          title:
                                              "Do you want to confirm this booking?"
                                                  .tr,
                                          onPressNegative: () {
                                            Get.back();
                                          },
                                          negativeButtonText: 'No'.tr,
                                          positiveButtonText: 'Yes'.tr,
                                          onPressPositive: () {
                                            Map<String, String> bodyParams = {
                                              'id_ride': data.id.toString(),
                                              'id_user':
                                                  data.idUserApp.toString(),
                                              'driver_name':
                                                  '${data.prenomConducteur.toString()} ${data.nomConducteur.toString()}',
                                              'lat_conducteur': data
                                                  .latitudeDepart
                                                  .toString(),
                                              'lng_conducteur': data
                                                  .longitudeDepart
                                                  .toString(),
                                              'lat_client': data.latitudeArrivee
                                                  .toString(),
                                              'lng_client': data
                                                  .longitudeArrivee
                                                  .toString(),
                                              'from_id': Preferences.getInt(
                                                      Preferences.userId)
                                                  .toString(),
                                            };

                                            controller
                                                .confirmedRide(bodyParams)
                                                .then((value) {
                                              if (value != null) {
                                                data.statut = "confirmed";
                                                Get.back();
                                                showDialog(
                                                    context: context,
                                                    builder:
                                                        (BuildContext context) {
                                                      return CustomDialogBox(
                                                        title:
                                                            "Confirmed Successfully"
                                                                .tr,
                                                        descriptions:
                                                            "Ride Successfully confirmed."
                                                                .tr,
                                                        text: "Ok".tr,
                                                        onPress: () {
                                                          Get.back();
                                                          controller
                                                              .getNewRide();
                                                          Get.offAll(
                                                              NewRideScreen());
                                                        },
                                                        img: Image.asset(
                                                            'assets/images/green_checked.png'),
                                                      );
                                                    });
                                              }
                                            });
                                          },
                                        );
                                      },
                                    );
                                  },
                                ),
                              ),
                            ),
                          ),
                          Visibility(
                            visible: data.statut == "confirmed" ? true : false,
                            child: Expanded(
                              child: Padding(
                                padding:
                                    const EdgeInsets.only(bottom: 5, left: 10),
                                child: ButtonThem.buildButton(
                                  context,
                                  title: 'on_ride'.tr,
                                  btnHeight: 45,
                                  btnWidthRatio: 0.8,
                                  btnColor: Colors.limeAccent,
                                  txtColor: Colors.black,
                                  onPress: () async {
                                    showDialog(
                                      barrierColor:
                                          const Color.fromARGB(66, 20, 14, 14),
                                      context: context,
                                      builder: (context) {
                                        return CustomAlertDialog(
                                          title:
                                              "Do you want to on ride this ride?"
                                                  .tr,
                                          negativeButtonText: 'No'.tr,
                                          positiveButtonText: 'Yes'.tr,
                                          onPressNegative: () {
                                            Get.back();
                                          },
                                          onPressPositive: () {
                                            Get.back();

                                            if (Constant.rideOtp.toString() !=
                                                    'yes' ||
                                                data.rideType! == 'driver') {
                                              Map<String, String> bodyParams = {
                                                'id_ride': data.id.toString(),
                                                'id_user':
                                                    data.idUserApp.toString(),
                                                'use_name':
                                                    '${data.prenomConducteur.toString()} ${data.nomConducteur.toString()}',
                                                'from_id': Preferences.getInt(
                                                        Preferences.userId)
                                                    .toString(),
                                              };
                                              controller
                                                  .setOnRideRequest(bodyParams)
                                                  .then((value) {
                                                if (value != null) {
                                                  Get.back();
                                                  showDialog(
                                                      context: context,
                                                      builder: (BuildContext
                                                          context) {
                                                        return CustomDialogBox(
                                                          title:
                                                              "On ride Successfully"
                                                                  .tr,
                                                          descriptions:
                                                              "Ride Successfully On ride."
                                                                  .tr,
                                                          text: "Ok".tr,
                                                          onPress: () {
                                                            controller
                                                                .getNewRide();
                                                          },
                                                          img: Image.asset(
                                                              'assets/images/green_checked.png'),
                                                        );
                                                      });
                                                }
                                              });
                                            } else {
                                              controller.otpController =
                                                  TextEditingController();
                                              showDialog(
                                                barrierColor: Colors.black26,
                                                context: context,
                                                builder: (context) {
                                                  return Dialog(
                                                    shape:
                                                        RoundedRectangleBorder(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              20),
                                                    ),
                                                    elevation: 0,
                                                    backgroundColor:
                                                        Colors.transparent,
                                                    child: Container(
                                                      height: 200,
                                                      padding:
                                                          const EdgeInsets.only(
                                                              left: 10,
                                                              top: 20,
                                                              right: 10,
                                                              bottom: 20),
                                                      decoration: BoxDecoration(
                                                          shape: BoxShape
                                                              .rectangle,
                                                          color: Colors.white,
                                                          borderRadius:
                                                              BorderRadius
                                                                  .circular(20),
                                                          boxShadow: const [
                                                            BoxShadow(
                                                                color: Colors
                                                                    .black,
                                                                offset: Offset(
                                                                    0, 10),
                                                                blurRadius: 10),
                                                          ]),
                                                      child: Column(
                                                        children: [
                                                          Text(
                                                            "Enter OTP".tr,
                                                            style: TextStyle(
                                                                color: Colors
                                                                    .black
                                                                    .withOpacity(
                                                                        0.60)),
                                                          ),
                                                          Pinput(
                                                            controller: controller
                                                                .otpController,
                                                            defaultPinTheme:
                                                                PinTheme(
                                                              height: 50,
                                                              width: 50,
                                                              textStyle: const TextStyle(
                                                                  letterSpacing:
                                                                      0.60,
                                                                  fontSize: 16,
                                                                  color: Colors
                                                                      .black,
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .w600),
                                                              // margin: EdgeInsets.all(10),
                                                              decoration:
                                                                  BoxDecoration(
                                                                borderRadius:
                                                                    BorderRadius
                                                                        .circular(
                                                                            10),
                                                                shape: BoxShape
                                                                    .rectangle,
                                                                color: Colors
                                                                    .white,
                                                                border: Border.all(
                                                                    color: Colors
                                                                        .limeAccent,
                                                                    width: 0.7),
                                                              ),
                                                            ),
                                                            keyboardType:
                                                                TextInputType
                                                                    .phone,
                                                            textInputAction:
                                                                TextInputAction
                                                                    .done,
                                                            length: 6,
                                                          ),
                                                          Row(
                                                            children: [
                                                              Expanded(
                                                                child: ButtonThem
                                                                    .buildButton(
                                                                  context,
                                                                  title:
                                                                      'done'.tr,
                                                                  btnHeight: 45,
                                                                  btnWidthRatio:
                                                                      0.8,
                                                                  btnColor: Colors
                                                                      .limeAccent,
                                                                  txtColor:
                                                                      Colors
                                                                          .black,
                                                                  onPress: () {
                                                                    if (controller
                                                                            .otpController
                                                                            .text
                                                                            .toString()
                                                                            .length ==
                                                                        6) {
                                                                      controller
                                                                          .verifyOTP(
                                                                        userId: data
                                                                            .idUserApp!
                                                                            .toString(),
                                                                        rideId: data
                                                                            .id!
                                                                            .toString(),
                                                                      )
                                                                          .then(
                                                                              (value) {
                                                                        if (value !=
                                                                                null &&
                                                                            value['success'] ==
                                                                                "success") {
                                                                          Map<String, String>
                                                                              bodyParams =
                                                                              {
                                                                            'id_ride':
                                                                                data.id.toString(),
                                                                            'id_user':
                                                                                data.idUserApp.toString(),
                                                                            'use_name':
                                                                                '${data.prenomConducteur.toString()} ${data.nomConducteur.toString()}',
                                                                            'from_id':
                                                                                Preferences.getInt(Preferences.userId).toString(),
                                                                          };
                                                                          controller
                                                                              .setOnRideRequest(bodyParams)
                                                                              .then((value) {
                                                                            if (value !=
                                                                                null) {
                                                                              Get.back();
                                                                              showDialog(
                                                                                  context: context,
                                                                                  builder: (BuildContext context) {
                                                                                    return CustomDialogBox(
                                                                                      title: "On ride Successfully".tr,
                                                                                      descriptions: "Ride Successfully On ride.".tr,
                                                                                      text: "Ok".tr,
                                                                                      onPress: () {
                                                                                        Get.back();
                                                                                        controller.getNewRide();
                                                                                      },
                                                                                      img: Image.asset('assets/images/green_checked.png'),
                                                                                    );
                                                                                  });
                                                                            }
                                                                          });
                                                                        }
                                                                      });
                                                                    } else {
                                                                      ShowToastDialog.showToast(
                                                                          'Please Enter OTP'
                                                                              .tr);
                                                                    }
                                                                  },
                                                                ),
                                                              ),
                                                              const SizedBox(
                                                                width: 8,
                                                              ),
                                                              Expanded(
                                                                child: ButtonThem
                                                                    .buildBorderButton(
                                                                  context,
                                                                  title:
                                                                      'cancel'
                                                                          .tr,
                                                                  btnHeight: 45,
                                                                  btnWidthRatio:
                                                                      0.8,
                                                                  btnColor: Colors
                                                                      .limeAccent,
                                                                  txtColor:
                                                                      Colors
                                                                          .black,
                                                                  btnBorderColor: Colors
                                                                      .black
                                                                      .withOpacity(
                                                                          0.20),
                                                                  onPress: () {
                                                                    Get.back();
                                                                  },
                                                                ),
                                                              )
                                                            ],
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                  );
                                                },
                                              );
                                            }
                                            // if (data.carDriverConfirmed == 1) {
                                            //
                                            // } else if (data.carDriverConfirmed == 2) {
                                            //   Get.back();
                                            //   ShowToastDialog.showToast("Customer decline the confirmation of driver and car information.");
                                            // } else if (data.carDriverConfirmed == 0) {
                                            //   Get.back();
                                            //   ShowToastDialog.showToast("Customer needs to verify driver and car before you can start trip.");
                                            // }
                                          },
                                        );
                                      },
                                    );
                                  },
                                ),
                              ),
                            ),
                          ),
                          Visibility(
                            visible: data.statut == "on ride" ? true : false,
                            child: Expanded(
                              child: Padding(
                                padding: const EdgeInsets.only(bottom: 5),
                                child: ButtonThem.buildBorderButton(
                                  context,
                                  title: 'START RIDE'.tr,
                                  btnHeight: 45,
                                  btnWidthRatio: 0.8,
                                  btnColor: Colors.limeAccent,
                                  txtColor: Colors.black,
                                  btnBorderColor:
                                      Colors.black.withOpacity(0.20),
                                  onPress: () async {
                                    MapsLauncher.launchCoordinates(
                                        double.parse(
                                            data.latitudeArrivee.toString()),
                                        double.parse(
                                            data.longitudeArrivee.toString()));
                                    // Constant.launchMapURl(data.latitudeArrivee,
                                    //     data.longitudeArrivee);
                                  },
                                ),
                              ),
                            ),
                          ),
                          Visibility(
                            visible: data.statut == "on ride" ? true : false,
                            child: Expanded(
                              child: Padding(
                                padding:
                                    const EdgeInsets.only(bottom: 5, left: 10),
                                child: ButtonThem.buildButton(
                                  context,
                                  title: 'COMPLETE'.tr,
                                  btnHeight: 45,
                                  btnWidthRatio: 0.8,
                                  btnColor: Colors.limeAccent,
                                  txtColor: Colors.black,
                                  onPress: () async {
                                    showDialog(
                                      barrierColor: Colors.black26,
                                      context: context,
                                      builder: (context) {
                                        return CustomAlertDialog(
                                          title:
                                              "Do you want to complete this ride?"
                                                  .tr,
                                          onPressNegative: () {
                                            Get.back();
                                          },
                                          negativeButtonText: 'No'.tr,
                                          positiveButtonText: 'Yes'.tr,
                                          onPressPositive: () {
                                            Map<String, String> bodyParams = {
                                              'id_ride': data.id.toString(),
                                              'id_user':
                                                  data.idUserApp.toString(),
                                              'driver_name':
                                                  '${data.prenomConducteur.toString()} ${data.nomConducteur.toString()}',
                                              'from_id': Preferences.getInt(
                                                      Preferences.userId)
                                                  .toString(),
                                            };
                                            controller
                                                .setCompletedRequest(
                                                    bodyParams, data)
                                                .then((value) {
                                              if (value != null) {
                                                Get.back();
                                                showDialog(
                                                    context: context,
                                                    builder:
                                                        (BuildContext context) {
                                                      return CustomDialogBox(
                                                        title:
                                                            "Completed Successfully"
                                                                .tr,
                                                        descriptions:
                                                            "Ride Successfully completed."
                                                                .tr,
                                                        text: "Ok".tr,
                                                        onPress: () {
                                                          Get.back();
                                                          controller
                                                              .getNewRide();
                                                        },
                                                        img: Image.asset(
                                                            'assets/images/green_checked.png'),
                                                      );
                                                    });
                                              }
                                            });
                                          },
                                        );
                                      },
                                    );
                                  },
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    )
                  ],
                ),
              ),
            ),
          ),
          Positioned(
              right: 0,
              child: Image.asset(
                data.statut == "new"
                    ? 'assets/images/new.png'
                    : data.statut == "confirmed"
                        ? 'assets/images/conformed.png'
                        : data.statut == "on ride"
                            ? 'assets/images/onride.png'
                            : data.statut == "completed"
                                ? 'assets/images/completed.png'
                                : 'assets/images/rejected.png',
                height: 120,
                width: 120,
              )),
        ],
      ),
    );
  }

  buildShowBottomSheet(
      BuildContext context, RideData data, NewRideController controller) {
    return showModalBottomSheet(
        shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.only(
                topRight: Radius.circular(15), topLeft: Radius.circular(15))),
        context: context,
        isDismissible: true,
        isScrollControlled: true,
        builder: (context) {
          return StatefulBuilder(builder: (context, setState) {
            return Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 15.0, vertical: 10),
              child: Padding(
                padding: MediaQuery.of(context).viewInsets,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      child: Text(
                        "Cancel Trip".tr,
                        style:
                            const TextStyle(fontSize: 18, color: Colors.black),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(top: 10),
                      child: Text(
                        "Write a reason for trip cancellation".tr,
                        style: TextStyle(color: Colors.black.withOpacity(0.50)),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: TextField(
                        controller: resonController,
                        keyboardType: TextInputType.text,
                        textInputAction: TextInputAction.done,
                        decoration: const InputDecoration(
                          focusedBorder: OutlineInputBorder(
                            borderSide:
                                BorderSide(color: Colors.grey, width: 1.0),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderSide:
                                BorderSide(color: Colors.grey, width: 1.0),
                          ),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(top: 20),
                      child: Row(
                        children: [
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.only(bottom: 5),
                              child: ButtonThem.buildButton(
                                context,
                                title: 'Cancel Trip'.tr,
                                btnHeight: 45,
                                btnWidthRatio: 0.8,
                                btnColor: Colors.limeAccent,
                                txtColor: Colors.black,
                                onPress: () async {
                                  if (resonController.text.isNotEmpty) {
                                    Get.back();
                                    showDialog(
                                      barrierColor: Colors.black26,
                                      context: context,
                                      builder: (context) {
                                        return CustomAlertDialog(
                                          title:
                                              "Do you want to reject this booking?"
                                                  .tr,
                                          onPressNegative: () {
                                            Get.back();
                                          },
                                          negativeButtonText: 'No'.tr,
                                          positiveButtonText: 'Yes'.tr,
                                          onPressPositive: () {
                                            Map<String, String> bodyParams = {
                                              'id_ride': data.id.toString(),
                                              'id_user':
                                                  data.idUserApp.toString(),
                                              'name':
                                                  '${data.prenomConducteur.toString()} ${data.nomConducteur.toString()}',
                                              'from_id': Preferences.getInt(
                                                      Preferences.userId)
                                                  .toString(),
                                              'user_cat': controller
                                                  .userModel!.userData!.userCat
                                                  .toString(),
                                              'reason': resonController.text
                                                  .toString(),
                                            };
                                            controller
                                                .canceledRide(bodyParams)
                                                .then((value) {
                                              Get.back();
                                              if (value != null) {
                                                showDialog(
                                                    context: context,
                                                    builder:
                                                        (BuildContext context) {
                                                      return CustomDialogBox(
                                                        title:
                                                            "Reject Successfully"
                                                                .tr,
                                                        descriptions:
                                                            "Ride Successfully rejected."
                                                                .tr,
                                                        text: "Ok".tr,
                                                        onPress: () {
                                                          Get.back();
                                                          controller
                                                              .getNewRide();
                                                        },
                                                        img: Image.asset(
                                                            'assets/images/green_checked.png'),
                                                      );
                                                    });
                                              }
                                            });
                                          },
                                        );
                                      },
                                    );
                                  } else {
                                    ShowToastDialog.showToast(
                                        "Please enter a reason".tr);
                                  }
                                },
                              ),
                            ),
                          ),
                          Expanded(
                            child: Padding(
                              padding:
                                  const EdgeInsets.only(bottom: 5, left: 10),
                              child: ButtonThem.buildBorderButton(
                                context,
                                title: 'Close'.tr,
                                btnHeight: 45,
                                btnWidthRatio: 0.8,
                                btnColor: Colors.limeAccent,
                                txtColor: Colors.black,
                                btnBorderColor: Colors.limeAccent,
                                onPress: () async {
                                  Get.back();
                                },
                              ),
                            ),
                          ),
                        ],
                      ),
                    )
                  ],
                ),
              ),
            );
          });
        });
  }
}

class VehicleInfoProvider extends ChangeNotifier {
  String _selectedCategoryID = "";

  String get selectedCategoryID => _selectedCategoryID;

  void setSelectedCategoryID(String categoryID) {
    _selectedCategoryID = categoryID;
    notifyListeners();
  }

  // Add any other methods or properties you need for state management

  static VehicleInfoProvider of(BuildContext context, {bool listen = false}) =>
      Provider.of<VehicleInfoProvider>(context, listen: listen);
}
