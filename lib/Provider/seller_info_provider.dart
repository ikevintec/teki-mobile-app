import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:salespro_saas_admin/model/seller_info_model.dart';

import '../Repo/seller_info_repo.dart';




SellerInfoRepo profileRepo = SellerInfoRepo();
final sellerInfoProvider = FutureProvider<List<SellerInfoModel>>((ref) => profileRepo.getAllSeller());