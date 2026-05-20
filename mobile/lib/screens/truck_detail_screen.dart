import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:fl_chart/fl_chart.dart';
import '../models/truck.dart';
import '../widgets/pulsing_dot.dart';
import '../core/theme.dart';
import '../providers/navigation_provider.dart';
import '../providers/sensors_provider.dart';
import 'agent_trace_screen.dart';
import 'simulated_actions_screen.dart';

class CargoDetails {
  final String shipmentId;
  final String clientName;
  final String valuePKR;
  final String quantity;
  final IconData icon;

  CargoDetails({
    required this.shipmentId,
    required this.clientName,
    required this.valuePKR,
    required this.quantity,
    required this.icon,
  });
}

class RouteTimes {
  final String departure;
  final String expectedArrival;

  RouteTimes({required this.departure, required this.expectedArrival});
}

class TruckDetailScreen extends ConsumerWidget {
  final Truck truck;

  const TruckDetailScreen({super.key, required this.truck});

  String _getTruckStatus(Truck currentTruck) {
    if (currentTruck.status == 'breach' && currentTruck.currentTemp > currentTruck.thresholdTemp) {
      return 'BREACH';
    } else if (currentTruck.thresholdTemp - currentTruck.currentTemp <= 2.0) {
      return 'ELEVATED';
    } else {
      return 'NORMAL';
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'BREACH':
        return AppTheme.danger;
      case 'ELEVATED':
        return Colors.orange;
      default:
        return AppTheme.success;
    }
  }

  LinearGradient _getBgGradient(String status) {
    switch (status) {
      case 'BREACH':
        return AppTheme.dangerGradient;
      case 'ELEVATED':
        return const LinearGradient(
          colors: [Color(0xFFF59E0B), Color(0xFFD97706)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
      default:
        return AppTheme.successGradient;
    }
  }

  String _expandCity(String code) {
    switch (code.toUpperCase()) {
      case 'KARACHI': return 'Karachi, Pakistan';
      case 'LAHORE': return 'Lahore, Pakistan';
      case 'ISLAMABAD': return 'Islamabad, Pakistan';
      case 'PESHAWAR': return 'Peshawar, Pakistan';
      case 'QUETTA': return 'Quetta, Pakistan';
      case 'MULTAN': return 'Multan, Pakistan';
      case 'FAISALABAD': return 'Faisalabad, Pakistan';
      case 'NY': return 'New York';
      case 'LA': return 'Los Angeles';
      case 'TX': return 'Houston, TX';
      case 'FL': return 'Miami, FL';
      case 'WA': return 'Seattle, WA';
      case 'OR': return 'Portland, OR';
      case 'IL': return 'Chicago, IL';
      case 'MI': return 'Detroit, MI';
      case 'OH': return 'Columbus, OH';
      case 'PA': return 'Philadelphia, PA';
      case 'CA': return 'San Francisco, CA';
      case 'NV': return 'Las Vegas, NV';
      case 'NJ': return 'Newark, NJ';
      case 'GA': return 'Atlanta, GA';
      case 'SC': return 'Charleston, SC';
      case 'CO': return 'Denver, CO';
      case 'UT': return 'Salt Lake City, UT';
      case 'AZ': return 'Phoenix, AZ';
      case 'NM': return 'Albuquerque, NM';
      default: return code;
    }
  }

  RouteTimes _getRouteTimes(Truck currentTruck) {
    final hash = currentTruck.truckId.hashCode % 5;
    switch (hash) {
      case 0:
        return RouteTimes(departure: 'May 17, 08:30 AM', expectedArrival: 'May 18, 04:00 PM');
      case 1:
        return RouteTimes(departure: 'May 17, 10:15 AM', expectedArrival: 'May 18, 09:30 PM');
      case 2:
        return RouteTimes(departure: 'May 16, 06:00 PM', expectedArrival: 'May 18, 11:00 AM');
      case 3:
        return RouteTimes(departure: 'May 17, 02:45 PM', expectedArrival: 'May 19, 08:00 AM');
      default:
        return RouteTimes(departure: 'May 17, 05:20 AM', expectedArrival: 'May 18, 02:30 PM');
    }
  }

  CargoDetails _getCargoDetails(Truck currentTruck) {
    final String cargoType = currentTruck.cargoType.toLowerCase();

    IconData icon;
    if (cargoType.contains('vaccine') || cargoType.contains('insulin')) {
      icon = Icons.medical_services_outlined;
    } else if (cargoType.contains('dairy')) {
      icon = Icons.water_drop_outlined;
    } else if (cargoType.contains('meat') || cargoType.contains('seafood')) {
      icon = Icons.set_meal_outlined;
    } else if (cargoType.contains('blood') || cargoType.contains('sample')) {
      icon = Icons.bloodtype_outlined;
    } else if (cargoType.contains('frozen') || cargoType.contains('produce') || cargoType.contains('kitchen')) {
      icon = Icons.kitchen_outlined;
    } else {
      icon = Icons.local_shipping_outlined;
    }

    switch (currentTruck.truckId) {
      case 'TRK-001':
        return CargoDetails(shipmentId: 'SHIP-001-VAC', clientName: 'National Health Services', valuePKR: '18,500,000', quantity: '40,000 vials', icon: icon);
      case 'TRK-002':
        return CargoDetails(shipmentId: 'SHIP-002-PRD', clientName: 'FreshMart Distributors', valuePKR: '1,200,000', quantity: '200 crates', icon: icon);
      case 'TRK-003':
        return CargoDetails(shipmentId: 'SHIP-003-DRY', clientName: 'Indus Dairies Co.', valuePKR: '1,800,000', quantity: '1,200 gallons', icon: icon);
      case 'TRK-004':
        return CargoDetails(shipmentId: 'SHIP-004-VAC', clientName: 'MedLife Pharmaceuticals', valuePKR: '25,000,000', quantity: '60,000 vials', icon: icon);
      case 'TRK-005':
        return CargoDetails(shipmentId: 'SHIP-005-MET', clientName: 'Fine Cuts Meats', valuePKR: '3,500,000', quantity: '4,000 kg', icon: icon);
      case 'TRK-006':
        return CargoDetails(shipmentId: 'SHIP-006-PRD', clientName: 'Metro Grocers', valuePKR: '1,400,000', quantity: '250 crates', icon: icon);
      case 'TRK-007':
        return CargoDetails(shipmentId: 'SHIP-007-DRY', clientName: 'Punjab Dairies Ltd.', valuePKR: '2,200,000', quantity: '1,500 gallons', icon: icon);
      case 'TRK-008':
        return CargoDetails(shipmentId: 'SHIP-008-MET', clientName: 'Al-Safa Halal Meat', valuePKR: '4,000,000', quantity: '4,500 kg', icon: icon);
      case 'TRK-009':
        return CargoDetails(shipmentId: 'SHIP-009-VAC', clientName: 'Apex Pharmaceuticals', valuePKR: '22,000,000', quantity: '50,000 vials', icon: icon);
      case 'TRK-010':
        return CargoDetails(shipmentId: 'SHIP-010-PRD', clientName: 'Hyperstar Logistics', valuePKR: '1,100,000', quantity: '180 crates', icon: icon);
      default:
        final shipmentNum = currentTruck.truckId.replaceAll(RegExp(r'[^0-9]'), '');
        final isVaccine = cargoType.contains('vaccine');
        final valStr = isVaccine ? '20,000,000' : '1,500,000';
        final qtyStr = isVaccine ? '50,000 vials' : '300 units';
        final clName = isVaccine ? 'National Pharma Corp' : 'Al-Rahman Logistics';
        return CargoDetails(
          shipmentId: 'SHIP-$shipmentNum-FLB',
          clientName: clName,
          valuePKR: valStr,
          quantity: qtyStr,
          icon: icon,
        );
    }
  }

  List<FlSpot> _generateHistorySpots(Truck currentTruck, String status) {
    final list = <FlSpot>[];
    final isBreached = status == 'BREACH';
    final isElevated = status == 'ELEVATED';

    double current = currentTruck.currentTemp;
    double threshold = currentTruck.thresholdTemp;

    for (int i = 0; i < 10; i++) {
      double tempVal;
      if (i == 9) {
        tempVal = current;
      } else {
        if (isBreached) {
          double start = threshold - 3.0;
          double diff = current - start;
          tempVal = start + (diff / 9.0) * i + (sin(i) * 0.4);
        } else if (isElevated) {
          double target = threshold - 1.0;
          tempVal = target + (sin(i) * 0.5) + ((current - target) / 9.0) * i;
        } else {
          double start = current - 1.5;
          double diff = current - start;
          tempVal = start + (diff / 9.0) * i + (cos(i) * 0.3);
        }
      }
      list.add(FlSpot(i.toDouble(), tempVal));
    }
    return list;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sensorsAsync = ref.watch(sensorsProvider);
    final liveTruck = sensorsAsync.maybeWhen(
      data: (trucks) => trucks.firstWhere((t) => t.truckId == truck.truckId, orElse: () => truck),
      orElse: () => truck,
    );

    final status = _getTruckStatus(liveTruck);
    final statusColor = _getStatusColor(status);
    final bgGradient = _getBgGradient(status);
    final isBreached = status == 'BREACH';

    return Scaffold(
      body: Column(
        children: [
          _buildHeader(context, liveTruck, status, statusColor, bgGradient),
          Expanded(
            child: ScrollConfiguration(
              behavior: const ScrollBehavior().copyWith(scrollbars: false),
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildTemperatureSection(context, liveTruck, isBreached, statusColor),
                    _buildChartSection(context, liveTruck, status, statusColor),
                    _buildDriverSection(context, liveTruck),
                    _buildCargoSection(context, liveTruck),
                    if (isBreached) _buildActionButtons(context, ref, liveTruck),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, Truck currentTruck, String status, Color statusColor, LinearGradient bgGradient) {
    return Container(
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 16,
        bottom: 24,
        left: 16,
        right: 16,
      ),
      decoration: BoxDecoration(
        gradient: bgGradient,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(32),
          bottomRight: Radius.circular(32),
        ),
        boxShadow: [
          BoxShadow(
            color: statusColor.withOpacity(0.25),
            blurRadius: 15,
            offset: const Offset(0, 5),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 20),
                onPressed: () => Navigator.pop(context),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 4,
                    )
                  ]
                ),
                child: Text(
                  status,
                  style: TextStyle(
                    color: statusColor,
                    fontWeight: FontWeight.w900,
                    fontSize: 12,
                    letterSpacing: 0.8,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.only(left: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  currentTruck.truckId,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Driver: ${currentTruck.driverName}  •  ${currentTruck.cargoType}',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTemperatureSection(BuildContext context, Truck currentTruck, bool isBreached, Color statusColor) {
    final excess = currentTruck.currentTemp - currentTruck.thresholdTemp;
    // Static looking but realistic updated time
    final formattedTime = 'Just now';

    return Card(
      margin: const EdgeInsets.fromLTRB(16, 20, 16, 10),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'TELEMETRY READINGS',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.0,
                    color: context.onSurfaceVariant,
                  ),
                ),
                Row(
                  children: [
                    PulsingDot(color: statusColor, size: 7),
                    const SizedBox(width: 6),
                    Text(
                      formattedTime,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: context.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(
                  '${currentTruck.currentTemp.toStringAsFixed(1)}°C',
                  style: TextStyle(
                    fontSize: 48,
                    fontWeight: FontWeight.w900,
                    color: statusColor,
                  ),
                ),
                const SizedBox(width: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Limit: ${currentTruck.thresholdTemp.toStringAsFixed(1)}°C',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: context.onSurfaceVariant,
                      ),
                    ),
                    if (isBreached) ...[
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppTheme.danger.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: AppTheme.danger.withOpacity(0.3)),
                        ),
                        child: Text(
                          'Excess: +${excess.toStringAsFixed(1)}°C',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            color: AppTheme.danger,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.05);
  }

  Widget _buildChartSection(BuildContext context, Truck currentTruck, String status, Color statusColor) {
    final spots = _generateHistorySpots(currentTruck, status);
    final temps = spots.map((s) => s.y).toList();
    temps.add(currentTruck.thresholdTemp);
    final minY = temps.reduce(min) - 1.5;
    final maxY = temps.reduce(max) + 1.5;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'TEMPERATURE TIMELINE (LAST 10 READINGS)',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.0,
                color: context.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              height: 180,
              child: LineChart(
                LineChartData(
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    horizontalInterval: 4.0,
                    getDrawingHorizontalLine: (value) {
                      return FlLine(
                        color: context.outline.withOpacity(0.15),
                        strokeWidth: 1,
                        dashArray: [5, 5],
                      );
                    },
                  ),
                  titlesData: FlTitlesData(
                    show: true,
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 28,
                        interval: 2,
                        getTitlesWidget: (value, meta) {
                          String text;
                          switch (value.toInt()) {
                            case 0: text = '18m ago'; break;
                            case 2: text = '14m ago'; break;
                            case 4: text = '10m ago'; break;
                            case 6: text = '6m ago'; break;
                            case 8: text = '2m ago'; break;
                            case 9: text = 'now'; break;
                            default: text = '';
                          }
                          return SideTitleWidget(
                            axisSide: meta.axisSide,
                            space: 6,
                            child: Text(
                              text,
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                                color: context.onSurfaceVariant.withOpacity(0.6),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 38,
                        interval: 4.0,
                        getTitlesWidget: (value, meta) {
                          return SideTitleWidget(
                            axisSide: meta.axisSide,
                            space: 6,
                            child: Text(
                              '${value.toStringAsFixed(0)}°C',
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                                color: context.onSurfaceVariant.withOpacity(0.6),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  borderData: FlBorderData(show: false),
                  minX: 0,
                  maxX: 9,
                  minY: minY,
                  maxY: maxY,
                  lineBarsData: [
                    LineChartBarData(
                      spots: spots,
                      isCurved: true,
                      barWidth: 3,
                      color: statusColor.withOpacity(0.65),
                      belowBarData: BarAreaData(
                        show: true,
                        color: statusColor.withOpacity(0.06),
                      ),
                      dotData: FlDotData(
                        show: true,
                        getDotPainter: (spot, percent, barData, index) {
                          final isSpotBreach = spot.y > currentTruck.thresholdTemp;
                          return FlDotCirclePainter(
                            radius: 4,
                            color: isSpotBreach ? AppTheme.danger : AppTheme.success,
                            strokeWidth: 1.5,
                            strokeColor: Colors.white,
                          );
                        },
                      ),
                    ),
                  ],
                  extraLinesData: ExtraLinesData(
                    horizontalLines: [
                      HorizontalLine(
                        y: currentTruck.thresholdTemp,
                        color: AppTheme.danger,
                        strokeWidth: 1.5,
                        dashArray: [6, 4],
                        label: HorizontalLineLabel(
                          show: true,
                          alignment: Alignment.topRight,
                          style: const TextStyle(
                            color: AppTheme.danger,
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                          ),
                          labelResolver: (line) => 'Threshold: ${currentTruck.thresholdTemp.toStringAsFixed(1)}°C',
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    ).animate().fadeIn(duration: 400.ms, delay: 100.ms).slideY(begin: 0.05);
  }

  Widget _buildDriverSection(BuildContext context, Truck currentTruck) {
    final times = _getRouteTimes(currentTruck);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'LOGISTICS & OPERATOR INFO',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.0,
                color: context.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: AppTheme.primary.withOpacity(0.12),
                  radius: 20,
                  child: const Icon(Icons.person_outline, color: AppTheme.primary),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      currentTruck.driverName,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: context.onSurface,
                      ),
                    ),
                    Text(
                      'Primary Fleet Operator',
                      style: TextStyle(
                        fontSize: 11,
                        color: context.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 20),
            const Divider(height: 1, thickness: 1),
            const SizedBox(height: 16),
            Row(
              children: [
                const Icon(Icons.route_outlined, size: 18, color: AppTheme.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'ROUTE PATH',
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                          color: context.onSurfaceVariant.withOpacity(0.6),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${_expandCity(currentTruck.origin)} ➔ ${_expandCity(currentTruck.destination)}',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: context.onSurface,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'DEPARTURE TIME',
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                          color: context.onSurfaceVariant.withOpacity(0.6),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        times.departure,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: context.onSurface,
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'EXPECTED ARRIVAL',
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                          color: context.onSurfaceVariant.withOpacity(0.6),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        times.expectedArrival,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: context.onSurface,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    ).animate().fadeIn(duration: 400.ms, delay: 200.ms).slideY(begin: 0.05);
  }

  Widget _buildCargoSection(BuildContext context, Truck currentTruck) {
    final cargo = _getCargoDetails(currentTruck);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'CARGO MANIFEST',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.0,
                color: context.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppTheme.secondary.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(cargo.icon, color: AppTheme.secondary, size: 22),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        currentTruck.cargoType,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: context.onSurface,
                        ),
                      ),
                      Text(
                        'ID: ${cargo.shipmentId}',
                        style: TextStyle(
                          fontSize: 11,
                          color: context.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            const Divider(height: 1, thickness: 1),
            const SizedBox(height: 16),
            _buildCargoRow(context, 'CLIENT NAME', cargo.clientName),
            const SizedBox(height: 12),
            _buildCargoRow(context, 'PKR VALUE', '${cargo.valuePKR} PKR', isValuable: true),
            const SizedBox(height: 12),
            _buildCargoRow(context, 'TOTAL QUANTITY', cargo.quantity),
          ],
        ),
      ),
    ).animate().fadeIn(duration: 400.ms, delay: 300.ms).slideY(begin: 0.05);
  }

  Widget _buildCargoRow(BuildContext context, String label, String value, {bool isValuable = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 9,
            fontWeight: FontWeight.bold,
            color: context.onSurfaceVariant.withOpacity(0.6),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isValuable ? FontWeight.w900 : FontWeight.bold,
            color: isValuable ? AppTheme.primary : context.onSurface,
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons(BuildContext context, WidgetRef ref, Truck currentTruck) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
      child: Column(
        children: [
          Container(
            decoration: BoxDecoration(
              gradient: AppTheme.primaryGradient,
              borderRadius: BorderRadius.circular(AppTheme.radiusLg),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.primary.withOpacity(0.2),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ElevatedButton.icon(
              onPressed: () {
                ref.read(activeTruckProvider.notifier).state = currentTruck;
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => AgentTraceScreen(truck: currentTruck),
                  ),
                );
              },
              icon: const Icon(Icons.auto_awesome, size: 22, color: Colors.white),
              label: const Text(
                'RESOLVE WITH AI',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.5,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                foregroundColor: Colors.white,
                shadowColor: Colors.transparent,
                minimumSize: const Size(double.infinity, 54),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                ),
              ),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms, delay: 400.ms).slideY(begin: 0.05);
  }
}
