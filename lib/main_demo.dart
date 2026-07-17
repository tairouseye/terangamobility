import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'demo/demo_app.dart';
import 'demo/demo_services.dart';
import 'demo/demo_store.dart';
import 'demo/demo_vehicle_source.dart';
import 'providers/admin_client_providers.dart';
import 'providers/auth_providers.dart';
import 'providers/partner_providers.dart';
import 'providers/quote_providers.dart';
import 'providers/request_providers.dart';
import 'providers/vehicle_catalog_providers.dart';
import 'providers/vehicle_order_providers.dart';
import 'providers/vehicle_providers.dart';

/// Point d'entree MODE DEMO (aucun backend requis).
///
/// Lancer avec :  flutter run -t lib/main_demo.dart
///
/// Supabase est initialise avec des identifiants factices : le client est
/// construit localement mais aucune requete reseau n'est faite car tous les
/// services sont remplaces par des implementations en memoire.
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://demo.supabase.co',
    publishableKey: 'sb_publishable_demo',
  );

  final store = DemoStore.instance..seed();
  final client = Supabase.instance.client;

  runApp(
    ProviderScope(
      overrides: [
        authServiceProvider.overrideWithValue(DemoAuthService(client)),
        storageServiceProvider.overrideWithValue(DemoStorageService(client)),
        currentProfileProvider.overrideWith((ref) async => demoProfile),
        vehicleServiceProvider
            .overrideWithValue(DemoVehicleService(client, store)),
        requestServiceProvider
            .overrideWithValue(DemoRequestService(client, store)),
        supplierQuoteServiceProvider
            .overrideWithValue(DemoSupplierQuoteService(client, store)),
        quoteServiceProvider.overrideWithValue(DemoQuoteService(client, store)),
        orderServiceProvider.overrideWithValue(DemoOrderService(client, store)),
        adminClientServiceProvider
            .overrideWithValue(DemoAdminClientService(client, store)),
        // Module vehicules Coree (catalogue en memoire + demande factice).
        vehicleDataSourceProvider.overrideWithValue(DemoVehicleDataSource()),
        vehicleRequestServiceProvider
            .overrideWithValue(DemoVehicleRequestService(client)),
        vehicleOrderServiceProvider
            .overrideWithValue(DemoVehicleOrderService(client)),
      ],
      child: const DemoApp(),
    ),
  );
}
