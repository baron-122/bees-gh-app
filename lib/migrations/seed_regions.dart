import 'package:cloud_firestore/cloud_firestore.dart';
import 'region_data.dart';

Future<void> seedRegionsToFirestore() async {
  final firestore = FirebaseFirestore.instance;
  final List<dynamic> regions = ghanaRegionData['Ghana']['regions'];

  for (final region in regions) {
    final regionName = region['name'];
    final regionRef = firestore.collection('regions').doc(regionName);

    await regionRef.set({'capital': region['capital']});

    for (final town in region['towns']) {
      final townName = town['name'];
      final townRef = regionRef.collection('towns').doc(townName);

      await townRef.set({}); // Set empty or add metadata

      for (final community in town['communities']) {
        await townRef
            .collection('communities')
            .doc(community)
            .set({'name': community});
      }
    }
  }

  print("✅ Ghana regional data seeded to Firestore.");
}
