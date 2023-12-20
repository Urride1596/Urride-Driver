class BikeDocuments {
  String? documentId;
  String? attachmentIndex;

  BikeDocuments({this.documentId, this.attachmentIndex});

  BikeDocuments.fromJson(Map<String, dynamic> json) {
    documentId = json['document_id'];
    attachmentIndex = json['attachmentIndex'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['document_id'] = documentId;
    data['attachmentIndex'] = attachmentIndex;
    return data;
  }
}
