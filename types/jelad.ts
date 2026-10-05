export type JobType = "RIDE" | "DELIVERY" | "CARGO" | "CORPORATE_TRIP" | "HEALTH_DELIVERY" | "SCHOOL_COMMUTE" | "EXPRESS_DELIVERY" | "FREIGHT";
export type JobStatus = "REQUESTED" | "SEARCHING" | "ASSIGNED" | "DRIVER_ARRIVING" | "IN_PROGRESS" | "COMPLETED" | "CANCELLED" | "REJECTED" | "EXPIRED";
export type PaymentMethod = "CASH" | "ZAIN_CASH" | "ORANGE_MONEY" | "EFAWATEERCOM";
export type DriverTier = "STANDARD" | "SILVER" | "GOLD" | "PLATINUM";
export type PayoutMethod = "ZAIN_CASH" | "ORANGE_MONEY" | "BANK";
export type LandmarkCategory = "university" | "hospital" | "mall" | "airport" | "transit_hub";

export interface PriceBreakdown { base?: number; distance?: number; waiting?: number; surge?: number; fees?: number; discount?: number; total?: number; [key:string]: unknown; }
export interface Landmark { id:string; name_ar:string; name_en:string; city:string; category:LandmarkCategory; latitude:number; longitude:number; pickup_instructions:string|null; }
export interface DriverJobOffer { id:string; type:JobType; status:JobStatus; destination:string; estimated_amount:number; net_earnings:number; pickup_distance_km:number; pickup_eta_minutes:number; passenger_count:number; luggage_count:number; payment_method:PaymentMethod; landmark?:Landmark|null; }
export interface PublicTripTracking { id:string; status:JobStatus; type:JobType; pickup:Record<string,unknown>|null; destination:Record<string,unknown>|null; driver:{name:string|null;avatar_url:string|null;rating:number;latitude:number|null;longitude:number|null;location_updated_at:string|null}|null; vehicle:{make:string;model:string;plate_number:string;color:string|null}|null; }
