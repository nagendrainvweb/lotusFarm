import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:lotus_farm/model/UserData.dart';
import 'package:lotus_farm/model/address_data.dart';
import 'package:lotus_farm/model/basic_response.dart';
import 'package:lotus_farm/model/dashboard_data.dart';
import 'package:lotus_farm/model/notification_data.dart';
import 'package:lotus_farm/model/offerResponse.dart';
import 'package:lotus_farm/model/order_details_data.dart';
import 'package:lotus_farm/model/pastOrderData.dart';
import 'package:lotus_farm/model/product_data.dart';
import 'package:lotus_farm/model/product_details_data.dart';
import 'package:lotus_farm/model/search_data.dart';
import 'package:lotus_farm/model/state_data.dart';
import 'package:lotus_farm/model/storeData.dart';
import 'package:lotus_farm/model/updateCartResponse.dart';
import 'package:lotus_farm/prefrence_util/Prefs.dart';
import 'package:lotus_farm/services/base_request.dart';
import 'package:lotus_farm/extension/extensions.dart';
import 'package:http/http.dart' as http;
import 'package:lotus_farm/utils/api_error_exception.dart';
import 'package:lotus_farm/utils/urlList.dart';
import 'package:lotus_farm/utils/utility.dart';

import '../utils/constants.dart';

class ApiService extends BaseRequest {
  Future<BasicResponse<String>> sendOtp(mobile, otp) async {
    try {
      final commonFeilds = _getCommonFeild();
      final body = {"mobile": mobile, "otp": otp};
      body.addAll(commonFeilds);
      myPrint(body.toString());
      final request = await http.post(Uri.parse(UrlList.SEND_OTP), body: body);
      final jsonResponse = json.decode(request.body);
      myPrint("otp response : ${request.body.toString()}");
      return BasicResponse.fromJson(json: jsonResponse, data: "");
    } on SocketException catch (e) {
      throw ApiErrorException(NO_INTERNET_CONN);
    } on Exception catch (e) {
      // sendMail(UrlList.SEND_OTP, SOMETHING_WRONG_TEXT);
      throw ApiErrorException(SOMETHING_WRONG_TEXT);
    }
  }

  Future<BasicResponse<String>> fetchUpdate() async {
    try {
      final commonFeilds = _getCommonFeild();
      final request =
          await http.post(Uri.parse(UrlList.CHECK_UPDATE), body: commonFeilds);
      myPrint(request.toString());
      final jsonResponse = json.decode(request.body);
      return BasicResponse.fromJson(json: jsonResponse, data: "");
    } on SocketException catch (e) {
      throw ApiErrorException(NO_INTERNET_CONN);
    } on Exception catch (e) {
      throw ApiErrorException(e.toString());
    }
  }

  /*  Fetch Token api */
  Future<BasicResponse<String>> fetchToken(String number) async {
    try {
      final commonFeilds = _getCommonFeild();
      final body = {
        "mobileNumber": number,
      };
      body.addAll(commonFeilds);
      final request = await http.post(Uri.parse(UrlList.REGISTER_TOKEN),
          headers: headers, body: body);
      if (request.statusCode == 200) {
        final jsonResponse = json.decode(request.body);
        return BasicResponse.fromJson(json: jsonResponse, data: "");
      }
    } on SocketException catch (e) {
      throw ApiErrorException(NO_INTERNET_CONN);
    } on Exception catch (e) {
      //sendMail(UrlList.CHECK_UPDATE, SOMETHING_WRONG_TEXT);
      throw ApiErrorException(e.toString());
    }
  }

  /*  Login Page api */
  Future<BasicResponse<User>> fetchUserlogin(String number) async {
    try {
      final commonFeilds = _getCommonFeild();
      final fcmToken = await Prefs.fcmToken;
      final body = {"mobileNumber": number, "fcm_token": "$fcmToken"};
      body.addAll(commonFeilds);
      myPrint(body.toString());
      final request = await http
          .post(Uri.parse(UrlList.USER_LOGIN), body: body)
          .timeout(Duration(seconds: 30));
      myPrint(request.body.toString());

      if (request.statusCode == 200) {
        final jsonResponse = json.decode(request.body);
        var data = jsonResponse['data'];
        if (data != null) {
          data = User.fromJson(data);
        }
        return BasicResponse.fromJson(json: jsonResponse, data: data);
      }
    } on SocketException catch (e) {
      throw ApiErrorException(NO_INTERNET_CONN);
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  Future<BasicResponse<String>> registerToken() async {
    final fcm_token = await Prefs.fcmToken;
    final user_id = await Prefs.userId;
    try {
      final commonFeilds = _getCommonFeild();
      final body = {"user_id": '$user_id', "fcm_token": '$fcm_token'};
      body.addAll(commonFeilds);
      final request =
          await http.post(Uri.parse(UrlList.REGISTER_TOKEN), body: body);
      myPrint(request.body.toString());
      final jsonResponse = json.decode(request.body);
      return BasicResponse.fromJson(json: jsonResponse, data: "");
    } on SocketException catch (e) {
      throw ApiErrorException(NO_INTERNET_CONN);
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  /*  Register Page api */
  Future<BasicResponse<User>> registerUser(
      firstName, lastName, mobileNumber, email, password, imagebase64) async {
    final fcm_token = await Prefs.fcmToken;
    final commonFeilds = _getCommonFeild();
    final postJson = {
      "mobileNumber": '$mobileNumber',
      "first_name": '$firstName',
      "last_name": '$lastName',
      "imageBase64": '$imagebase64',
      "email": '$email',
      "password": '$password',
      "fcm_token": '$fcm_token'
    };
    postJson.addAll(commonFeilds);
    myPrint(postJson.toString());
    myPrint(UrlList.USER_REGISTRATION);
    try {
      final request =
          await http.post(Uri.parse(UrlList.USER_REGISTRATION), body: postJson);
      myPrint(request.body);
      if (request.statusCode == 200) {
        final jsonResponse = json.decode(request.body);
        myPrint(jsonResponse.toString());
        var jsondata = jsonResponse['data'];
        User user;
        if (jsonResponse[UrlConstants.STATUS] == UrlConstants.SUCCESS) {
          if (jsondata != null) {
            user = User.fromJson(jsondata);
          }
        }
        return BasicResponse.fromJson(json: jsonResponse, data: user);
      }
    } on SocketException catch (e) {
      throw ApiErrorException(NO_INTERNET_CONN);
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  Future<BasicResponse<DashboardData>> fetchDashboard() async {
    try {
      final userId = await Prefs.userId;
      final commonFeild = _getCommonFeild();
      final postJson = {
        "user_id": "$userId",
      };
      postJson.addAll(commonFeild);
      final request = await http.post(Uri.parse(UrlList.FETCH_DASHBOARD),
          body: postJson, headers: await _getHeader());
      myPrint(request.body);
      final jsonResponse = json.decode(request.body);
      final basicResponse =
          BasicResponse<DashboardData>.fromJson(json: jsonResponse);
      var data = jsonResponse[UrlConstants.DATA];
      if (data != null) {
        data = DashboardData.fromJson(jsonResponse[UrlConstants.DATA]);
        basicResponse.data = data;
      }
      return basicResponse;
    } on SocketException catch (e) {
      throw ApiErrorException(NO_INTERNET_CONN);
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  Future<BasicResponse<List<Product>>> fetchAllProducts() async {
    try {
      final userId = await Prefs.userId;
      final body = {"user_id": "$userId"};
      final request =
          await http.post(Uri.parse(UrlList.FETCH_ALL_PRODICTS), body: body);
      myPrint(request.body);

      final jsonResponse = json.decode(request.body);
      final data = jsonResponse[UrlConstants.DATA];
      final response =
          BasicResponse<List<Product>>.fromJson(json: jsonResponse);
      final List<Product> productList = [];
      if (response.status == Constants.SUCCESS) {
        final items = data["items"];
        for (var map in items) {
          productList.add(Product.fromJson(map));
        }
        response.data = productList;
        return response;
      } else {
        throw Exception(jsonResponse["message"]);
      }
    } on SocketException catch (e) {
      throw ApiErrorException(NO_INTERNET_CONN);
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  Future<BasicResponse<List<Product>>> fetchPreOrderList() async {
    try {
      final userId = await Prefs.userId;
      final body = {"user_id": "$userId"};
      myPrint(body.toString());
      final request =
          await http.post(Uri.parse(UrlList.PRE_ORDER_LIST), body: body);
      myPrint(request.body);
      final jsonResponse = json.decode(request.body);
      final data = jsonResponse[UrlConstants.DATA];
      final response =
          BasicResponse<List<Product>>.fromJson(json: jsonResponse);
      final List<Product> productList = [];
      if (response.status == Constants.SUCCESS) {
        final items = data["items"];
        for (var map in items) {
          productList.add(Product.fromJson(map));
        }
        response.data = productList;
        return response;
      } else {
        throw Exception(jsonResponse["message"]);
      }
    } on SocketException catch (e) {
      throw ApiErrorException(NO_INTERNET_CONN);
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  Future<BasicResponse<OfferResponse>> fetchOffers() async {
    final userid = await Prefs.userId;
    final commonFeilds = _getCommonFeild();
    final postJson = {
      "user_id": "$userid",
    };
    postJson.addAll(commonFeilds);
    try {
      final request = await http.post(Uri.parse(UrlList.FETCH_OFFERS),
          body: postJson, headers: await _getHeader());
      print("offer response is " + request.body.toString());
      final response = json.decode(request.body);
      var data = response[UrlConstants.DATA];
      //Prefs.setOfferResponse(request.body);
      if (data != null) {
        data = OfferResponse.fromJson(data);
        // minimumOrderValue = data.minimumVal;
        // maximumOrderValue = data.maximumVal;
      }
      return BasicResponse.fromJson(json: response, data: data);
    } on SocketException catch (e) {
      throw ApiErrorException(NO_INTERNET_CONN);
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  Future<BasicResponse<String>> updateProfileDetails(
      firstName, lastName, mobileNumber, city, email) async {
    final userid = await Prefs.userId;
    final commonFeilds = _getCommonFeild();
    final postJson = {
      "user_id": '$userid',
      "first_name": '$firstName',
      "last_name": '$lastName',
      "city": '$city',
      "email": '$email',
    };
    postJson.addAll(commonFeilds);
    myPrint(postJson.toString());
    try {
      final request = await http.post(Uri.parse(UrlList.UPDATE_USER_DETAILS),
          body: postJson, headers: await _getHeader());
      myPrint(request.body);
      final jsonResponse = json.decode(request.body);

      final basicResponse =
          BasicResponse<String>.fromJson(json: jsonResponse, data: "");
      return basicResponse;
    } on SocketException catch (e) {
      throw ApiErrorException(NO_INTERNET_CONN);
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  Future<BasicResponse<User>> fetchProfileDetails() async {
    try {
      final userId = await Prefs.userId;
      final commonFeilds = _getCommonFeild();
      final postJson = {
        "user_id": '$userId',
      };
      postJson.addAll(commonFeilds);
      myPrint(postJson.toString());
      final request = await http.post(Uri.parse(UrlList.FETCH_USER_DETAILS),
          headers: await _getHeader(), body: postJson);
      myPrint(request.body);
      if (request.statusCode == 200) {
        final jsonResponse = json.decode(request.body);
        var data = jsonResponse["data"];
        if (data != null) {
          data = User.fromJson(data);
          Prefs.setUserId(data.id);
          Prefs.setName(data.firstName);
          Prefs.setSurName(data.lastName);
          Prefs.setEmailId(data.emailId);
          Prefs.setMobileNumber(data.mobileNumber);
          Prefs.setCity(data.city);
          Prefs.setProfilePic(data.profile_pic);
        }
        return BasicResponse.fromJson(json: jsonResponse, data: data);
      }
    } on SocketException catch (e) {
      throw ApiErrorException(NO_INTERNET_CONN);
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  /*  Address Page api */
  Future<BasicResponse<List<AddressData>>> fetchAddress() async {
    final userId = await Prefs.userId;
    final commonFeilds = _getCommonFeild();
    final postJson = {
      "user_id": '$userId',
    };
    postJson.addAll(commonFeilds);
    myPrint(postJson.toString());
    try {
      final result = await http.post(Uri.parse(UrlList.FETCH_ADDRESSES),
          headers: await _getHeader(), body: postJson);
      myPrint(result.body);
      final response = json.decode(result.body);
      final basicResponse =
          BasicResponse<List<AddressData>>.fromJson(json: response);
      List<AddressData> items = [];
      if (basicResponse.status == Constants.SUCCESS) {
        var data = response["data"];
        if (data != null) {
          data.forEach((v) {
            final data = new AddressData.fromJson(v);
            if (data.state != null && data.pincode != null) {
              myPrint("lat ${data.latitude}");
              myPrint("lng ${data.longitude}");
              items.add(new AddressData.fromJson(v));
            }
          });
        }
        basicResponse.data = items;
      }
      return basicResponse;
    } on SocketException catch (e) {
      throw ApiErrorException(NO_INTERNET_CONN);
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  Future<BasicResponse<List<PastOrderData>>> fetchPastOrders() async {
    final userId = await Prefs.userId;
    final commonFeilds = _getCommonFeild();
    final postJson = {
      "user_id": '$userId',
    };
    postJson.addAll(commonFeilds);
    myPrint(postJson.toString());
    try {
      final result = await http.post(Uri.parse(UrlList.FETCH_PAST_ORDERS),
          headers: await _getHeader(), body: postJson);
      myPrint(result.body);
      final response = json.decode(result.body);
      final basicResponse =
          BasicResponse<List<PastOrderData>>.fromJson(json: response);
      List<PastOrderData> items = [];
      if (basicResponse.status == Constants.SUCCESS) {
        var data = response["data"];
        if (data != null) {
          data.forEach((v) {
            final data = new PastOrderData.fromJson(v);
            items.add(data);
          });
        }
        basicResponse.data = items;
      }
      return basicResponse;
    } on SocketException catch (e) {
      throw ApiErrorException(NO_INTERNET_CONN);
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  Future<BasicResponse<OrderDetailsData>> fetchOrderDetails(
      String orderId) async {
    final userId = await Prefs.userId;
    final commonFeilds = _getCommonFeild();
    final postJson = {"user_id": '$userId', "order_id": "$orderId"};
    postJson.addAll(commonFeilds);
    myPrint(postJson.toString());
    try {
      final result = await http.post(Uri.parse(UrlList.FETCH_ORDER_DETAILS),
          headers: await _getHeader(), body: postJson);
      myPrint(result.body);
      final response = json.decode(result.body);
      final basicResponse =
          BasicResponse<OrderDetailsData>.fromJson(json: response);
      if (basicResponse.status == Constants.SUCCESS) {
        OrderDetailsData data = OrderDetailsData.fromJson(response["data"]);
        basicResponse.data = data;
      } else {
        throw Exception(basicResponse..message);
      }
      return basicResponse;
    } on SocketException catch (e) {
      throw ApiErrorException(NO_INTERNET_CONN);
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  Future<BasicResponse<List<SearchData>>> fetchSearchData(
      var searchText) async {
    try {
      final commonFeilds = _getCommonFeild();
      final postJson = {
        "text": '$searchText',
      };
      postJson.addAll(commonFeilds);
      myPrint(postJson.toString());

      final result =
          await http.post(Uri.parse(UrlList.FETCH_SEARCH_DATA), body: postJson);
      myPrint(result.body);
      final response = json.decode(result.body);
      final basicResponse =
          BasicResponse<List<SearchData>>.fromJson(json: response);
      List<SearchData> items = [];
      if (basicResponse.status == Constants.SUCCESS) {
        var data = response["data"];
        if (data != null) {
          data.forEach((v) {
            final data = new SearchData.fromJson(v);
            items.add(data);
          });
        }
        basicResponse.data = items;
      }
      return basicResponse;
    } on SocketException catch (e) {
      throw ApiErrorException(NO_INTERNET_CONN);
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  Future<BasicResponse<ProductDetailsData>> fetchProductDetails(
      var productId) async {
    final commonFeilds = _getCommonFeild();
    final postJson = {"product_id": '$productId'};
    postJson.addAll(commonFeilds);
    myPrint(postJson.toString());
    try {
      final result = await http.post(Uri.parse(UrlList.FETCH_PRODUCT_DETAILS),
          body: postJson);
      myPrint(result.body.toString());
      final response = json.decode(result.body);
      final basicResponse =
          BasicResponse<ProductDetailsData>.fromJson(json: response);
      if (basicResponse.status == Constants.SUCCESS) {
        ProductDetailsData data =
            ProductDetailsData.fromJson(response[Constants.DATA]);
        basicResponse.data = data;
      }
      return basicResponse;
    } on SocketException catch (e) {
      throw ApiErrorException(NO_INTERNET_CONN);
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  Future<BasicResponse<List<Product>>> fetchCartDetails() async {
    final userId = await Prefs.userId;
    final commonFeilds = _getCommonFeild();
    final postJson = {
      "user_id": '$userId',
    };
    postJson.addAll(commonFeilds);
    myPrint(postJson.toString());

    try {
      final request = await http.post(Uri.parse(UrlList.FETCH_CART_DATA),
          headers: await _getHeader(), body: postJson);
      final jsonResponse = json.decode(request.body);
      final basicResponse =
          BasicResponse<List<Product>>.fromJson(json: jsonResponse);
      final data = jsonResponse[UrlConstants.DATA];
      List<Product> productlist = [];
      if (data != null) {
        List itemsArray = data['product'];
        for (var i = 0; i < itemsArray.length; i++) {
          productlist.add(Product.fromJson(itemsArray[i]));
        }
        basicResponse.data = productlist;
      }
      return basicResponse;
    } on SocketException catch (e) {
      throw ApiErrorException(NO_INTERNET_CONN);
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  Future<BasicResponse<String>> addToCart(
      String productId, var qty, var sizeId) async {
    final userid = await Prefs.userId;
    final commonFeilds = _getCommonFeild();
    final postJson = {
      "user_id": '$userid',
      "product_id": '$productId',
      "qty": '$qty',
      "size": '$sizeId',
    };
    postJson.addAll(commonFeilds);
    myPrint(postJson.toString());
    try {
      final request = await http.post(Uri.parse(UrlList.ADD_TO_CART),
          headers: await _getHeader(), body: postJson);
      myPrint(request.body);
      final response = json.decode(request.body);
      final basicResponse = BasicResponse<String>.fromJson(json: response);
      return basicResponse;
    } on SocketException catch (e) {
      throw ApiErrorException(NO_INTERNET_CONN);
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  Future<BasicResponse<String>> removeFromCart(
      var productId, var sizeId) async {
    final userid = await Prefs.userId;
    final commonFeilds = _getCommonFeild();
    final postJson = {
      "user_id": '$userid',
      "product_id": '$productId',
      "size": '$sizeId',
    };
    postJson.addAll(commonFeilds);
    myPrint(postJson.toString());
    final request = await http.post(Uri.parse(UrlList.REMOVE_FROM_CART),
        headers: await _getHeader(), body: postJson);
    try {
      final jsonResponse = json.decode(request.body);
      myPrint(request.body.toString());
      return BasicResponse.fromJson(json: jsonResponse, data: "");
    } on SocketException catch (e) {
      throw ApiErrorException(NO_INTERNET_CONN);
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  Future<BasicResponse<List<StateData>>> fetchStateList() async {
    try {
      final request = await http.post(Uri.parse(UrlList.FETCH_STATE_LIST));
      final response = json.decode(request.body);
      final basicResponse =
          BasicResponse<List<StateData>>.fromJson(json: response);
      List data = response[UrlConstants.DATA];
      List<StateData> stateList = [];
      if (basicResponse.status == Constants.SUCCESS) {
        if (data != null) {
          Prefs.setStateList(json.encode(data));
          for (var item in data) {
            stateList.add(StateData.fromJson(item));
          }
        }
      }
      basicResponse.data = stateList;

      return basicResponse;
    } on SocketException catch (e) {
      throw ApiErrorException(NO_INTERNET_CONN);
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  Future<BasicResponse<String>> addUpdateAddress(
      AddressData addressData) async {
    final userid = await Prefs.userId;
    final commonfeild = _getCommonFeild();
    var postJson = addressData.toJson();
    postJson['user_id'] = '$userid';
    postJson.addAll(commonfeild);
    myPrint(postJson.toString());
    // final postJson =
    //     {"user_id": $userid,"address_id":$address_id,"name":$name,"isDetault":$isDetault,"type":$type,"number":$number,"email_id":$email_id,"flat_no":$flat_no,"street_name":$street_name,"area":$area,"landmark":$landmark,"city":$city,"state":$state,"pincode":$pincode,"appVersion": $appversion, "device": $device};
    try {
      final request = await http.post(Uri.parse(UrlList.ADD_EDIT_ADDRESS),
          headers: await _getHeader(), body: postJson);
      myPrint(request.body.toString());
      final jsonResponse = json.decode(request.body);
      return BasicResponse<String>.fromJson(json: jsonResponse, data: "");
    } on SocketException catch (e) {
      throw ApiErrorException(NO_INTERNET_CONN);
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  Future<BasicResponse<String>> deleteAddress(var addressId) async {
    final userid = await Prefs.userId;
    final commonfeild = _getCommonFeild();
    final postJson = {
      "user_id": '$userid',
      "address_id": '$addressId',
    };
    postJson.addAll(commonfeild);
    myPrint(postJson.toString());
    try {
      final request = await http.post(Uri.parse(UrlList.DELETE_ADDRESS),
          headers: await _getHeader(), body: postJson);
      myPrint(request.body.toString());
      final jsonResponse = json.decode(request.body);
      return BasicResponse<String>.fromJson(json: jsonResponse, data: "");
    } on SocketException catch (e) {
      throw ApiErrorException(NO_INTERNET_CONN);
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  Future<BasicResponse<UpdateCartResponse>> updateCart(
      List<Product> cartList, String coupon_title, String total_amount) async {
    final userid = await Prefs.userId;
    final commonFeild = _getCommonFeild();
    Map<String, dynamic> body = new Map<String, dynamic>();
    body['user_id'] = '$userid';
    body['coupon_code'] = '$coupon_title';
    body['total_amount'] = '$total_amount';
    body.addAll(commonFeild);
    List data = [];
    for (var product in cartList) {
      data.add(product.toCartJson());
    }
    body['data'] = data;
    final postBody = json.encode(body);
    myPrint(json.encode(body.toString()));
    // calling api
    try {
      final request = await http.post(Uri.parse(UrlList.UPDATE_CART),
          body: postBody, headers: await _getHeader());
      myPrint(request.body.toString());
      final jsonRequest = json.decode(request.body);
      var data;
      if (jsonRequest[UrlConstants.STATUS] == UrlConstants.SUCCESS) {
        data = UpdateCartResponse.fromJson(jsonRequest[UrlConstants.DATA]);
      }
      return BasicResponse.fromJson(json: jsonRequest, data: data);
    } on SocketException catch (e) {
      throw ApiErrorException(NO_INTERNET_CONN);
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  Future<BasicResponse<List<Product>>> fetchProductList(
      var pageNo, var categoryid) async {
    final userId = await Prefs.userId;
    final common = _getCommonFeild();
    final postJson = {
      "user_id": '$userId',
      "pageNo": '$pageNo',
      "category_id": '$categoryid',
    };
    postJson.addAll(common);
    myPrint(postJson.toString());
    try {
      final request = await http.post(Uri.parse(UrlList.FETCH_PRODUCTS),
          headers: await _getHeader(), body: postJson);
      myPrint(request.body);
      final jsonResponse = json.decode(request.body);
      final basicResponse =
          BasicResponse<List<Product>>.fromJson(json: jsonResponse);
      var data = jsonResponse[UrlConstants.DATA];
      final links = data["links"];
      final List<Product> list = [];
      if (data != null) {
        final jsonList = data["items"];
        for (var map in jsonList) {
          list.add(Product.fromJson(map));
        }
      }
      basicResponse.data = list;
      basicResponse.links = Links.fromJson(links);
      return basicResponse;
    } on SocketException catch (e) {
      throw ApiErrorException(NO_INTERNET_CONN);
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  Future<BasicResponse<List<StoreData>>> fetchStoreList() async {
    final userId = await Prefs.userId;
    final common = _getCommonFeild();
    final postJson = {
      "user_id": '$userId',
    };
    postJson.addAll(common);
    myPrint(postJson.toString());
    try {
      final request = await http.post(Uri.parse(UrlList.STORE_LIST),
          headers: await _getHeader(), body: postJson);
      final jsonResponse = json.decode(request.body);
      final basicResponse =
          BasicResponse<List<StoreData>>.fromJson(json: jsonResponse);
      var data = jsonResponse[UrlConstants.DATA];
      final List<StoreData> list = [];
      if (data != null) {
        for (var map in data) {
          list.add(StoreData.fromJson(map));
        }
      }
      basicResponse.data = list;
      return basicResponse;
    } on SocketException catch (e) {
      throw ApiErrorException(NO_INTERNET_CONN);
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  Future<BasicResponse<List<NotificationData>>> fetchNotification() async {
    final userId = await Prefs.userId;
    final date  = await Prefs.loginDate;
    final common = _getCommonFeild();
    final postJson = {
      "user_id": '$userId',
      "date":'$date'
    };
    postJson.addAll(common);
    myPrint(postJson.toString());
    try {
      final request = await http.post(Uri.parse(UrlList.FETCH_NOTIFICATIONS),
          headers: await _getHeader(), body: postJson);
      print("noti response " + request.body.toString());
      final jsonResponse = json.decode(request.body);
      final basicResponse =
          BasicResponse<List<NotificationData>>.fromJson(json: jsonResponse);
      if (basicResponse.status == Constants.SUCCESS) {
        var data = jsonResponse[UrlConstants.DATA];
        final List<NotificationData> list = [];
        if (data != null) {
          for (var map in data) {
            list.add(NotificationData.fromJson(map));
          }
        }
        basicResponse.data = list;
        return basicResponse;
      }
      throw ApiErrorException(basicResponse.message);
    } on SocketException catch (e) {
      throw ApiErrorException(NO_INTERNET_CONN);
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  Future<BasicResponse<String>> deleteNotification(
      String notificationId) async {
    final commonBody = _getCommonFeild();
    final user_id = await Prefs.userId;
    final token = await Prefs.token;
    final body = {
      Constants.USERID: "$user_id",
      Constants.NOTIFICATION_ID: "$notificationId"
    };
    body.addAll(commonBody);
    myPrint(body.toString());
    try {
      final result = await http.post(Uri.parse(UrlList.DELETE_NOTIFICATION),
          body: body, headers: await _getHeader());
      myPrint(result.body.toString());
      final response = json.decode(result.body);
      final basicResponse =
          BasicResponse<String>.fromJson(json: response, data: "");
      if (basicResponse.status == Constants.SUCCESS) {
        return basicResponse;
      }
      throw ApiErrorException(basicResponse.message);
    } on SocketException catch (e) {
      throw ApiErrorException(NO_INTERNET_CONN);
    } on TimeoutException catch (e) {
      throw ApiErrorException(NO_INTERNET_CONN);
    } on Exception catch (e) {
      myPrint(e.toString());
      throw ApiErrorException(SOMETHING_WRONG_TEXT);
    }
  }

  Future<BasicResponse<String>> readNotifications(
      String notificationIds) async {
    final userid = await Prefs.userId;

    final common = _getCommonFeild();
    final postJson = {
      "user_id": '$userid',
      'notification_ids': '$notificationIds'
    };
    postJson.addAll(common);
    myPrint(postJson.toString());
    try {
      final request = await http.post(Uri.parse(UrlList.READ_NOTIFICATIONS),
          body: postJson, headers: await _getHeader());
      final response = json.decode(request.body);
      final basicResponse = BasicResponse<String>.fromJson(json: response);
      if (basicResponse.status == Constants.SUCCESS) {
        return basicResponse;
      }
      throw ApiErrorException(basicResponse.message);
      // var data = response[UrlConstants.DATA];
      // List<NotificationData> notificationList = List();
      // if (data != null) {
      //   for(var e in data){
      //     notificationList.add(NotificationData.fromJson(e));
      //   }
      // }
      //return BasicResponse.fromJson(json: response, data: "");
    } catch (e) {
      myPrint("error in api provider");
      throw Exception(e);
    }
  }

  Future<BasicResponse<List<Product>>> fetchOrderProductReview() async {
    final userId = await Prefs.userId;
    final commonFeilds = _getCommonFeild();
    final postJson = {
      "user_id": '$userId',
    };
    postJson.addAll(commonFeilds);

    try {
      final request = await http.post(
          Uri.parse(UrlList.FETCH_ORDER_PRODUCT_REVIEW),
          headers: await _getHeader(),
          body: postJson);
      final jsonResponse = json.decode(request.body);
      final basicResponse =
          BasicResponse<List<Product>>.fromJson(json: jsonResponse);
      final data = jsonResponse[UrlConstants.DATA];
      List<Product> productlist = [];
      if (data != null) {
        /// List itemsArray = data['product'];
        for (var i = 0; i < data.length; i++) {
          productlist.add(Product.fromJson(data[i]));
        }
        basicResponse.data = productlist;
      }
      return basicResponse;
    } on SocketException catch (e) {
      throw ApiErrorException(NO_INTERNET_CONN);
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  Future<BasicResponse<String>> addReview(
      var productId, var rating, var reviewTitle, var review) async {
    final userid = await Prefs.userId;
    final token = await Prefs.token;
    final firstName = await Prefs.name;
    Map<String, String> headers = {Constants.AUTH: "$token"};
    final postJson = {
      "user_id": '$userid',
      "product_id": '$productId',
      "rating": '$rating',
      "review_title": '$reviewTitle',
      "review": '$review',
      "name": "$firstName"
    };
    myPrint(postJson.toString());

    try {
      final request = await http.post(Uri.parse(UrlList.ADD_REVIEW),
          headers: headers, body: postJson);
      final jsonResponse = json.decode(request.body);
      final basicResponse = BasicResponse<String>.fromJson(json: jsonResponse);
      myPrint(request.body.toString());

      if (basicResponse.status == Constants.SUCCESS) {
        return basicResponse;
      } else {
        throw ApiErrorException(basicResponse.message);
      }
    } on SocketException catch (e) {
      throw ApiErrorException(NO_INTERNET_CONN);
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  Future<BasicResponse<Map<String, dynamic>>> placeOrder(
      String billingAddressId,
      String shippingAddressId,
      String couponCode,
      String offerType,
      String discountAmount,
      String deliveryDate,
      String pickupLat,
      String pickupLng,
      String droplat,
      String droplng,
      String shippingType,
      String method) async {
    final userId = await Prefs.userId;
    final common = _getCommonFeild();
    final postJson = {
      "user_id": "$userId",
      "billing_address_id": "$billingAddressId",
      "shipping_address_id": "$shippingAddressId",
      "coupon_code": "$couponCode",
      "offer_type": '$offerType',
      "discount_amount": "$discountAmount",
      "delivery_date": "$deliveryDate",
      "pickup_lat": "$pickupLat",
      "pickup_lng": "$pickupLng",
      "drop_lat": "$droplat",
      "drop_lng": "$droplng",
      "shipping_type": "$shippingType",
      "order_type": "$method"
    };
    postJson.addAll(common);
    myPrint(postJson.toString());
    try {
      final request = await http.post(Uri.parse(UrlList.PLACE_ORDER),
          headers: await _getHeader(), body: postJson);
      myPrint(request.body);
      final jsonResponse = json.decode(request.body);
      final basicResponse =
          BasicResponse<Map<String, dynamic>>.fromJson(json: jsonResponse);
      var data = jsonResponse[UrlConstants.DATA];
      basicResponse.data = data;
      return basicResponse;
    } on SocketException catch (e) {
      throw ApiErrorException(NO_INTERNET_CONN);
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  Future<BasicResponse<OrderDetailsData>> updatePayment(
      String order_id,
      String transaction_id,
      String paymentStatus,
      String payment_amount) async {
    final userid = await Prefs.userId;
    final common = _getCommonFeild();
    final postJson = {
      "user_id": "$userid",
      "order_id": "$order_id",
      "transaction_id": "$transaction_id",
      "payment_status": "$paymentStatus",
      "payment_amount": "$payment_amount",
    };
    postJson.addAll(common);
    myPrint(postJson.toString());
    try {
      final request = await http.post(Uri.parse(UrlList.UPDATE_PAYMENT),
          body: postJson, headers: await _getHeader());
      print(request.body.toString());
      final jsonResponse = json.decode(request.body);
      final basicResponse =
          BasicResponse<OrderDetailsData>.fromJson(json: jsonResponse);
      if (basicResponse.status == Constants.SUCCESS) {
        var data = jsonResponse[UrlConstants.DATA];
        if (data != null) {
          data = OrderDetailsData.fromJson(data);
          basicResponse.data = data;
        }
        return basicResponse;
      } else {
        throw ApiErrorException(basicResponse.message);
      }
    } on SocketException catch (e) {
      throw ApiErrorException(NO_INTERNET_CONN);
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  Future<BasicResponse<Offers>> verifyCoupons(
      String couponCode, String amount) async {
    final userid = await Prefs.userId;
    final common = _getCommonFeild();
    final postJson = {
      "user_id": "$userid",
      "coupon_code": "$couponCode",
      "paid_amount": "$amount",
    };
    postJson.addAll(common);
    myPrint(postJson.toString());

    try {
      final request = await http.post(Uri.parse(UrlList.VERIFY_COUPON_CODE),
          body: postJson, headers: await _getHeader());
      final response = json.decode(request.body);
      print(request.body);
      final basicResponse = BasicResponse.fromJson(json: response);
      if (basicResponse.status == Constants.SUCCESS) {
        var data = response[UrlConstants.DATA];
        data = Offers.fromJson(data, isOffer: false);
        basicResponse.data = data;
        return basicResponse;
      }
      throw ApiErrorException(basicResponse.message);
    } catch (e) {
      myPrint("inside catch");
      throw ApiErrorException(e);
    }
  }

  Future<BasicResponse<String>> sendQuery(name, email, number, desc) async {
    final userid = await Prefs.userId;
    final common = _getCommonFeild();

    final postJson = {
      "user_id": '$userid',
      "name": '$name',
      "email": '$email',
      "number": '$number',
      "query": '$desc',
    };
    postJson.addAll(common);
    myPrint(postJson.toString());
    final request = await http.post(Uri.parse(UrlList.SEND_ABOUT_US_QUERY),
        headers: headers, body: postJson);
    print(request.body);
    try {
      final jsonResponse = json.decode(request.body);
      return BasicResponse.fromJson(json: jsonResponse, data: "");
    } catch (e) {
      return throw Exception(e);
    }
  }

  Future<BasicResponse<String>> fetchCMSData(String pageName) async {
    final common = _getCommonFeild();
    final postJson = {
      "page_name": '$pageName',
    };
    postJson.addAll(common);
    myPrint(postJson.toString());
    final request = await http.post(Uri.parse(UrlList.CMS_DATA),
        headers: headers, body: postJson);
    print(request.body);
    try {
      final jsonResponse = json.decode(request.body);
      if (jsonResponse[Constants.STATUS] == Constants.SUCCESS) {
        if (pageName == "FAQ") {
          await Prefs.setFaq(jsonResponse['page_content']);
        } else if (pageName == "Terms & Condition") {
          await Prefs.setTerms(jsonResponse['page_content']);
        } else {
          await Prefs.setPrivacy(jsonResponse['page_content']);
        }
        return BasicResponse.fromJson(
            json: jsonResponse, data: jsonResponse['page_content']);
      } else {
        throw ApiErrorException(jsonResponse[Constants.MESSAGE]);
      }
    } catch (e) {
      return throw Exception(e);
    }
  }

  Future<BasicResponse<OrderDetailsData>> updatePaymentFree(
      String order_id, String payment_amount, String coupon_code) async {
    final userid = await Prefs.userId;
    final token = await Prefs.token;

    final postJson = {
      "user_id": "$userid",
      "order_id": "$order_id",
      "payment_amount": "$payment_amount",
      "coupon_code": "$coupon_code",
    };
    final common = _getCommonFeild();
    postJson.addAll(common);
    myPrint(postJson.toString());
    try {
      final request = await http.post(Uri.parse(UrlList.UPDATE_PAYMENT_FREE),
          body: postJson, headers: await _getHeader());
      myPrint(request.body.toString());
      final response = json.decode(request.body);

      var data = response[UrlConstants.DATA];
      if (data != null) {
        data = OrderDetailsData.fromJson(data);
        return BasicResponse.fromJson(json: response, data: data);
      }
      throw ApiErrorException(response[Constants.MESSAGE]);
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  // common fields like device and app version
  _getCommonFeild() {
    final device = Constants.DEVICE;
    final appversion = Constants.VERSION;

    final map = {
      Constants.APP_VERSION: appversion,
      Constants.URL_DEVICE: device
    };
    return map;
  }

  Future<Map<String, dynamic>> _getHeader() async {
    final token = await Prefs.token;
    final header = {Constants.AUTH: "$token"};
    myPrint(header.toString());
    return header;
  }
}
