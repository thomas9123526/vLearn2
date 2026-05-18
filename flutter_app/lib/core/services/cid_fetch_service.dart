import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Fetches the current user's CID from the public network.
///
/// TODO: Replace [fetchCid] body with the real public-network API call
/// once the endpoint and auth mechanism are known. The rest of the
/// app (sign-up / sign-in screens) already wires this up correctly.
class CidFetchService {
  Future<String> fetchCid() async {
    // Placeholder — simulates a short network round-trip.
    await Future<void>.delayed(const Duration(milliseconds: 800));
    // TODO: call real endpoint, e.g.:
    //   final res = await dio.get('https://public-cid-api.example.com/me');
    //   return res.data['cid'] as String;
    return '1234567890';
  }
}

final cidFetchServiceProvider =
    Provider<CidFetchService>((_) => CidFetchService());
