import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/truck.dart';

final activeTabIndexProvider = StateProvider<int>((ref) => 0);
final activeTruckProvider = StateProvider<Truck?>((ref) => null);
