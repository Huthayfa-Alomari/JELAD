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
  final bool womenOnly;
  final bool familyMode;
  const Job({required this.id,required this.type,required this.status,this.pickupLat,this.pickupLng,this.destinationLat,this.destinationLng,this.driverId,this.womenOnly=false,this.familyMode=false});
}
