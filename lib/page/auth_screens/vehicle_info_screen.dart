import 'dart:developer';

import 'package:urride_driver/constant/constant.dart';
import 'package:urride_driver/constant/show_toast_dialog.dart';
import 'package:urride_driver/controller/vehicle_info_controller.dart';
import 'package:urride_driver/model/vehicle_register_model.dart';
import 'package:urride_driver/page/auth_screens/add_profile_photo_screen.dart';
import 'package:urride_driver/page/auth_screens/bike_document_verify_screen.dart';
import 'package:urride_driver/page/auth_screens/document_verify_screen.dart';
import 'package:urride_driver/page/auth_screens/login_screen.dart';
import 'package:urride_driver/themes/constant_colors.dart';
import 'package:urride_driver/themes/responsive.dart';
import 'package:urride_driver/themes/text_field_them.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';


class VehicleInfoScreen extends StatelessWidget {
  VehicleInfoScreen({Key? key, required String phoneNumber}) : super(key: key);
  @override

  static final GlobalKey<FormState> _formKey = GlobalKey();
  final VehicleInfoController vehicleInfoController = VehicleInfoController();


  Future<void> _fetchVehicleCategories() async {
    await vehicleInfoController.getVehicleCategory();
  }

  get vehicleCategoryList => "";


  @override
  Widget build(BuildContext context) {

    vehicleInfoController.getVehicleCategory();
    _fetchVehicleCategories();
    bool keyboardIsOpen = MediaQuery
        .of(context)
        .viewInsets
        .bottom == 0;

    return SafeArea(
      child: Scaffold(
        extendBody: true,
        resizeToAvoidBottomInset: true,
        floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,

        backgroundColor: Colors.black87,

        body: WillPopScope(
          onWillPop: () async {
            Get.offAll(() => LoginScreen());
            return true;
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: SingleChildScrollView(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 20),
                    child: InkWell(
                      onTap: () {
                        vehicleInfoController.getVehicleCategory();
                      },

                      child: Text(
                        'Choose Your Vehicle Type'.tr,
                        style: const TextStyle(
                            fontSize: 22,
                            color: Colors.white,
                            letterSpacing: 1.5,
                            fontWeight: FontWeight.w500),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(top: 10.0),
                    child: SizedBox(
                      height: Responsive.height(80, context),
                      child: GridView.builder(
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 8.0,
                          mainAxisSpacing: 8.0,
                        ),
                        itemCount: vehicleInfoController.vehicleCategoryList.length,
                        itemBuilder: (BuildContext context, int index) {
                          return GestureDetector(
                            onTap: () {
                              vehicleInfoController.selectedCategoryID(vehicleInfoController.vehicleCategoryList[index].id.toString());
                            },
                            child: Obx(
                                  () => Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                                  decoration: BoxDecoration(
                                    color: vehicleInfoController.selectedCategoryID.value ==
                                        vehicleInfoController.vehicleCategoryList[index].id.toString()
                                        ? Colors.limeAccent
                                        : Colors.white,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                    children: [
                                      CachedNetworkImage(
                                        imageUrl: vehicleInfoController.vehicleCategoryList[index].image.toString(),
                                        fit: BoxFit.fill,
                                        width: 100,
                                        height: Responsive.height(10, context),
                                        placeholder: (context, url) => Constant.loader(),
                                        errorWidget: (context, url, error) => const Icon(Icons.error),
                                      ),
                                      Text(
                                        vehicleInfoController.vehicleCategoryList[index].libelle.toString(),
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),









                  const SizedBox(
                    height: 10,
                  ),
                  Visibility(
                    child: Center(
                      child: FloatingActionButton(
                        backgroundColor: Colors.limeAccent  ,
                        child: const Icon(
                          Icons.navigate_next,
                          size: 28,
                          color: Colors.black,
                        ),
                        onPressed: () async {

                          if (vehicleInfoController
                              .selectedCategoryID.value.isNotEmpty) {
                            Map<String, String> bodyParams1 = {
                              "id_categorie_vehicle": vehicleInfoController
                                  .selectedCategoryID.value,
                              "id_driver": vehicleInfoController
                                  .userModel!.userData!.id
                                  .toString(),
                            };
                            log(bodyParams1.toString());
                            await vehicleInfoController
                                .vehicleRegister(bodyParams1)
                                .then((value) {
                              if (vehicleInfoController.selectedCategoryID.value == "9") {
                                if (value?.success == "Success" ||
                                    value?.success == "success") {
                                  Get.to(() =>
                                      DocumentVerifyScreen(
                                        fromOtp: false,
                                      ));
                                }
                              } else if (vehicleInfoController.selectedCategoryID.value == "15") {
                                if (value?.success == "Success" ||
                                    value?.success == "success") {
                                  Get.to(() =>
                                      DocumentVerifyScreen(
                                        fromOtp: false,
                                      ));
                                }
                              } else if (vehicleInfoController.selectedCategoryID.value == "16") {
                                if (value?.success == "Success" ||
                                    value?.success == "success") {
                                  Get.to(() =>
                                      AddProfilePhotoScreen(
                                        fromOtp: false,
                                      ));
                                }
                              } else if (vehicleInfoController.selectedCategoryID.value == "17") {
                                if (value?.success == "Success" ||
                                    value?.success == "success") {
                                  Get.to(() =>
                                      DocumentVerifyScreen(
                                        fromOtp: false,
                                      ));
                                }
                              } else if (vehicleInfoController.selectedCategoryID.value == "18") {
                                if (value?.success == "Success" ||
                                    value?.success == "success") {
                                  Get.to(() =>
                                      BikeDocumentVerifyScreen(
                                        fromOtp: false,
                                      ));
                                }
                              } else if (vehicleInfoController.selectedCategoryID.value == "21") {
                                if (value?.success == "Success" ||
                                    value?.success == "success") {
                                  Get.to(() =>
                                      AddProfilePhotoScreen(
                                        fromOtp: false,
                                      ));
                                }
                              }

                              else {
                                ShowToastDialog.showToast(value?.error);
                              }
                            });
                            //Get.to(AddProfilePhotoScreen());
                          } else {
                            ShowToastDialog.showToast(
                                "Please select vehicle type".tr);
                          }

                        },
                      ),
                    ),
                  ),
                ]
              ),
    ),

    ),
    ),
      )
            );

  }


}
