import 'dart:developer';
import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:urride_driver/constant/show_toast_dialog.dart';
import 'package:urride_driver/controller/document_upload_contoller.dart';
import 'package:urride_driver/controller/documets.dart';
import 'package:urride_driver/controller/vehicle_info_controller.dart';
import 'package:urride_driver/model/document_model.dart';
import 'package:urride_driver/page/auth_screens/add_profile_photo_screen.dart';
import 'package:urride_driver/page/auth_screens/login_screen.dart';
import 'package:urride_driver/themes/button_them.dart';
import 'package:urride_driver/themes/constant_colors.dart';
import 'package:urride_driver/themes/responsive.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';

import '../../constant/constant.dart';
import '../../controller/bike_document_upload_contoller.dart';
import '../../controller/bikedocumets.dart';
final vehicleInfoController = Get.put(VehicleInfoController());
class BikeDocumentVerifyScreen extends StatelessWidget {
  final bool fromOtp;

  BikeDocumentVerifyScreen({Key? key, required this.fromOtp}) : super(key: key);


  @override
  Widget build(BuildContext context) {
    return GetX<BikeDocumentController>(
      init: BikeDocumentController(),
      builder: (bikecontroller) {
        return Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(
            elevation: 0,
            backgroundColor: Colors.black,
            leading: Padding(
              padding: const EdgeInsets.all(8.0),
              child: GestureDetector(
                onTap: () {
                  if (fromOtp) {
                    Get.offAll(() => LoginScreen());
                  } else {
                    Get.back();
                  }
                },
                child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(30),
                      color: Colors.white,
                      boxShadow: <BoxShadow>[
                        BoxShadow(
                          color: Colors.black.withOpacity(0.3),
                          blurRadius: 10,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: const Padding(
                      padding: EdgeInsets.all(8),
                      child: Icon(
                        Icons.arrow_back_ios_rounded,
                        color: Colors.black,
                      ),
                    )),
              ),
            ),
          ),
          body: WillPopScope(
            onWillPop: () async {
              if (fromOtp) {
                Get.offAll(() => LoginScreen());
                return true;
              } else {
                Get.back();
                return true;
              }
            },
            child: bikecontroller.isLoading.value
                ? const Center(
              child: CircularProgressIndicator(),
            )
                : Padding(
              padding: const EdgeInsets.symmetric(horizontal: 22.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    height: Responsive.height(2, context),
                  ),
                  Text(
                    'Add Bike Verification Document'.tr,
                    style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 1.2,
                        fontSize: 20),
                  ),
                  SizedBox(
                    height: Responsive.height(2, context),
                  ),
                  Expanded(
                    child: ListView.builder(
                      itemCount: bikecontroller.bikerideList.length,
                      shrinkWrap: true,
                      physics: const AlwaysScrollableScrollPhysics(),
                      itemBuilder: (context, index) {
                        return Column(
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    bikecontroller.bikerideList[index].title
                                        .toString(),
                                    style: const TextStyle(
                                        color: Colors.white),
                                  ),
                                ),
                                ButtonThem.buildButton(
                                  context,
                                  title: 'upload'.tr,
                                  btnHeight: 32,
                                  btnWidthRatio: 0.25,
                                  btnColor: Colors.limeAccent,
                                  txtColor: Colors.black,
                                  onPress: () {
                                    buildBottomSheet(
                                        context,
                                        bikecontroller as BikeDocumentController,
                                        index,
                                        bikecontroller.bikerideList[index].id
                                            .toString());
                                  },
                                ),
                              ],
                            ),
                            bikecontroller.imageList.isNotEmpty
                                ? bikecontroller.imageList[index].isNotEmpty
                                ? Image.file(
                              File(bikecontroller.imageList[index]),
                              height: Responsive.height(
                                  25, context),
                              width:
                              Responsive.width(90, context),
                              fit: BoxFit.cover,
                            )
                                : Container()
                                : Container()
                          ],
                        );
                      },
                    ),
                  ),
                  SizedBox(
                    height: Responsive.height(1, context),
                  ),
                ],
              ),
            ),
          ),
          bottomNavigationBar: Container(
            color: Colors.black,
            height: 80,
            width: Responsive.width(100, context),
            child: Center(
              child: ButtonThem.buildButton(
                context,
                title: 'next'.tr,
                btnHeight: 45,
                btnWidthRatio: 0.8,
                btnColor: Colors.limeAccent,
                txtColor: Colors.black,
                onPress: () {
                  log(bikecontroller.document.length.toString());
                  log(bikecontroller.bikerideList.length.toString());
                  if (bikecontroller.document.length ==
                      bikecontroller.bikerideList.length) {
                    // print("${controller.imageList.map((element) => element).toList()}");
                    // print("${controller.document.map((element) => element.toJson()).toList()}");

                    bikecontroller.uploadProfile().then((value) {
                      if (value != null) {
                        Get.offAll(AddProfilePhotoScreen(fromOtp: fromOtp));
                        buildAlertSendInformation(context);
                      }
                    });
                  } else {
                    ShowToastDialog.showToast('Please select All Documents'.tr);
                  }
                },
              ),
            ),
          ),
          floatingActionButtonLocation:
          FloatingActionButtonLocation.centerFloat,
        );
      },
    );
  }

  buildBottomSheet(BuildContext context, BikeDocumentController bikecontroller,
      int index, String documentId) {
    return showModalBottomSheet(
        context: context,
        builder: (context) {
          return StatefulBuilder(builder: (context, setState) {
            return Container(
              height: Responsive.height(22, context),
              color: Colors.white,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 15),
                    child: Text(
                      'please_select'.tr,
                      style: TextStyle(
                        color: const Color(0XFF333333).withOpacity(0.8),
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(18.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            IconButton(
                                onPressed: () => pickFile(bikecontroller as BikeDocumentController,
                                    source: ImageSource.camera,
                                    index: index,
                                    documentId: documentId),
                                icon: const Icon(
                                  Icons.camera_alt,
                                  size: 32,
                                )),
                            Padding(
                              padding: const EdgeInsets.only(top: 3),
                              child: Text('camera'.tr),
                            ),
                          ],
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(18.0),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            IconButton(
                                onPressed: () => pickFile(bikecontroller as BikeDocumentController,
                                    source: ImageSource.gallery,
                                    index: index,
                                    documentId: documentId),
                                icon: const Icon(
                                  Icons.photo_library_sharp,
                                  size: 32,
                                )),
                            Padding(
                              padding: const EdgeInsets.only(top: 3),
                              child: Text('gallery'.tr),
                            ),
                          ],
                        ),
                      )
                    ],
                  ),
                ],
              ),
            );
          });
        });
  }

  final ImagePicker _imagePicker = ImagePicker();

  Future pickFile(BikeDocumentController bikecontroller,
      {required ImageSource source,
        required int index,
        required String documentId}) async {
    try {
      XFile? image = await _imagePicker.pickImage(source: source);
      if (image != null) {
        bikecontroller.imageList.removeAt(index);
        bikecontroller.imageList.insert(index, image.path);

        BikeDocuments document = BikeDocuments(
            documentId: documentId, attachmentIndex: index.toString());
        if (index < bikecontroller.document.length) {
          bikecontroller.document.removeAt(index);
          bikecontroller.document.insert(index, document);
        } else {
          bikecontroller.document.add(document);
        }
        Get.back();
      }
    } on PlatformException catch (e) {
      ShowToastDialog.showToast("${"Failed to Pick".tr} : \n $e");
    } catch (e) {
      ShowToastDialog.showToast("${"Failed to Pick".tr}: \n $e");
    }
  }

  buildAlertSendInformation(
      BuildContext context,
      ) {
    return Get.defaultDialog(
      radius: 6,
      title: "",
      titleStyle: const TextStyle(fontSize: 0.0),
      content: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 15.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Image.asset(
                "assets/images/green_checked.png",
                height: 100,
                width: 100,
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12.0),
              child: Text(
                "${"Your information send well. We will treat them and inform you after the treatment.".tr} ${"Your account will be active after validation of your information.".tr}",
                textAlign: TextAlign.center,
                softWrap: true,
                style: const TextStyle(color: Colors.black54),
              ),
            ),
            const SizedBox(
              height: 20,
            ),
            ButtonThem.buildButton(context,
                title: "Close".tr,
                btnHeight: 40,
                btnWidthRatio: 0.6,
                btnColor: ConstantColors.primary,
                txtColor: Colors.white,
                onPress: () => Get.back()),
          ],
        ),
      ),
    );
  }
}
