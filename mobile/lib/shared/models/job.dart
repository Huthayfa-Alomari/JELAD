enum JobType { ride, delivery, cargo, corporateTrip, healthDelivery, schoolCommute, expressDelivery, freight }
enum JobStatus { requested, searching, assigned, driverArriving, inProgress, completed, cancelled, rejected, expired }

class Job {
  final String id;
  final JobType type;
  final JobStatus status;
  final double? pickupLat;
  final double? pickupLng;
  final double? destinationLat;
  final double? destinationLng;
  final String? driverId;
  final String? paymentMethod;
  final bool womenOnly;
  final bool familyMode;
  final DateTime? scheduledPickupTime;

  const Job({required this.id, required this.type, required this.status, this.pickupLat, this.pickupLng, this.destinationLat, this.destinationLng, this.driverId, this.paymentMethod, this.womenOnly=false, this.familyMode=false, this.scheduledPickupTime});
}
