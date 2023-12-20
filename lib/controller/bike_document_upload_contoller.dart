import 'dart:async';
import 'dart:convert';
import 'dart:developer';
import 'dart:io';

import 'package:urride_driver/constant/constant.dart';
import 'package:urride_driver/constant/show_toast_dialog.dart';
import 'package:urride_driver/controller/bikedocumets.dart';
import 'package:urride_driver/controller/documets.dart';
import 'package:urride_driver/model/document_model.dart';
import 'package:urride_driver/model/user_model.dart';
import 'package:urride_driver/service/api.dart';
import 'package:urride_driver/utils/Preferences.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;

import '../model/bike_document_model.dart';

class BikeDocumentController extends GetxController {
  String userCat = "driver";

  @override
  void onInit() {
    getUserdata();
    getCarServiceBooks();
    super.onInit();
  }

  getUserdata() async {
    UserModel? userModel = Constant.getUserData();
    userCat = userModel.userData!.userCat!;
  }

  var isLoading = true.obs;
  var bikerideList = <BikeDocumentData>[].obs;
  var document = <BikeDocuments>[].obs;
  var imageList = <String>[].obs;

  Future<dynamic> getCarServiceBooks() async {
    try {
      final response = await http.get(Uri.parse(API.bikedocumentList), headers: API.header);
      Map<String, dynamic> responseBody = json.decode(response.body);
      if (response.statusCode == 200 && responseBody['success'] == "success") {
        isLoading.value = false;
        BikeDocumentModel model = BikeDocumentModel.fromJson(responseBody);
        bikerideList.value = model.bikedocumentList!.cast<BikeDocumentData>();

        for (int i = 0; i < bikerideList.length; i++) {
          imageList.add("");
        }
      } else if (response.statusCode == 200 && responseBody['success'] == "Failed") {
        isLoading.value = false;
      } else {
        isLoading.value = false;
        ShowToastDialog.showToast('Something want wrong. Please try again later');
        throw Exception('Failed to load album');
      }
    } on TimeoutException catch (e) {
      isLoading.value = false;
      ShowToastDialog.showToast(e.message.toString());
    } on SocketException catch (e) {
      isLoading.value = false;
      ShowToastDialog.showToast(e.message.toString());
    } on Error catch (e) {
      isLoading.value = false;
      ShowToastDialog.showToast(e.toString());
    } catch (e) {
      ShowToastDialog.closeLoader();
      ShowToastDialog.showToast(e.toString());
    }
    return null;
  }

  Future<dynamic> uploadProfile() async {
    try {
      ShowToastDialog.showLoader("Please wait");

      var request = http.MultipartRequest(
        'POST',
        Uri.parse(API.bikedriverDocumentAdd),
      );
      request.headers.addAll(API.header);

      for (var element in imageList) {
        request.files.add(http.MultipartFile.fromBytes('attachment[]', File(element).readAsBytesSync(), filename: File(element).path.split('/').last));
      }

      request.fields['driver_id'] = Preferences.getInt(Preferences.userId).toString();
      request.fields['documents'] = jsonEncode(document);

      var res = await request.send();
      var responseData = await res.stream.toBytes();

      Map<String, dynamic> response = jsonDecode(String.fromCharCodes(responseData));

      if (res.statusCode == 200 && response['success'] == "success") {
        ShowToastDialog.closeLoader();
        ShowToastDialog.showToast("Uploaded!");
        return response;
      } else {
        ShowToastDialog.closeLoader();
        ShowToastDialog.showToast('Something want wrong. Please try again later');
        throw Exception('Failed to load album');
      }
    } on TimeoutException catch (e) {
      log(e.toString());
      ShowToastDialog.closeLoader();
      ShowToastDialog.showToast(e.message.toString());
    } on SocketException catch (e) {
      log(e.toString());
      ShowToastDialog.closeLoader();
      ShowToastDialog.showToast(e.message.toString());
    } on Error catch (e) {
      ShowToastDialog.closeLoader();
      ShowToastDialog.showToast(e.toString());
    } catch (e) {
      log(e.toString());
      ShowToastDialog.closeLoader();
      ShowToastDialog.showToast(e.toString());
    }
  }
}
