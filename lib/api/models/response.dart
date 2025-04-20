class ApiResponse {
  final int status;
  final String data;

  const ApiResponse({required this.status, required this.data});

  Map<String, dynamic> toJson() {
    return {"status": status, "data": data};
  }
}