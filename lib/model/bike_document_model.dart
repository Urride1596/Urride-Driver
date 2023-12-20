class BikeDocumentModel {
  String? success;
  String? error;
  String? message;
  List<BikeDocumentData>? bikedocumentList;

  BikeDocumentModel({this.success, this.error, this.message, this.bikedocumentList});

  BikeDocumentModel.fromJson(Map<String, dynamic> json) {
    success = json['success'].toString();
    error = json['error'].toString();
    message = json['message'].toString();
    if (json['data'] != null) {
      bikedocumentList = <BikeDocumentData>[];
      json['data'].forEach((v) {
        bikedocumentList!.add(BikeDocumentData.fromJson(v));
      });
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['success'] = success;
    data['error'] = error;
    data['message'] = message;
    if (bikedocumentList != null) {
      data['data'] = bikedocumentList!.map((v) => v.toJson()).toList();
    }
    return data;
  }
}

class BikeDocumentData {
  String? id;
  String? title;
  String? isEnabled;
  String? createdAt;
  String? updatedAt;

  BikeDocumentData({this.id, this.title, this.isEnabled, this.createdAt, this.updatedAt});

  BikeDocumentData.fromJson(Map<String, dynamic> json) {
    id = json['id'].toString();
    title = json['title'].toString();
    isEnabled = json['is_enabled'].toString();
    createdAt = json['created_at'].toString();
    updatedAt = json['updated_at'].toString();
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['title'] = title;
    data['is_enabled'] = isEnabled;
    data['created_at'] = createdAt;
    data['updated_at'] = updatedAt;
    return data;
  }
}
