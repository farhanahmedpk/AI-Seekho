import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/truck.dart';
import '../core/api_service.dart';
import '../core/demo_data.dart';
import 'demo_provider.dart';

class SensorsNotifier extends AsyncNotifier<List<Truck>> {
  @override
  Future<List<Truck>> build() async {
    // Re-fetch whenever demo mode changes
    ref.watch(demoModeProvider);
    return _fetch();
  }

  Future<List<Truck>> _fetch() async {
    final isDemoMode = ref.read(demoModeProvider);
    final apiService = ApiService();
    
    if (isDemoMode) {
      return DemoData.getInitialTrucks();
    }

    try {
      return await apiService.getSensors();
    } catch (e) {
      try {
        if (state.hasValue && state.value != null && state.value!.isNotEmpty) {
          return state.value!;
        }
      } catch (_) {}
      return DemoData.getInitialTrucks();
    }
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _fetch());
  }

  void setTrucks(List<Truck> trucks) {
    state = AsyncValue.data(trucks);
  }
}

final sensorsProvider = AsyncNotifierProvider<SensorsNotifier, List<Truck>>(SensorsNotifier.new);

final breachCountProvider = Provider<int>((ref) {
  final sensorsAsync = ref.watch(sensorsProvider);
  return sensorsAsync.maybeWhen(
    data: (trucks) => trucks.where((t) => t.status == 'breach' && t.currentTemp > t.thresholdTemp).length,
    orElse: () => 0,
  );
});
