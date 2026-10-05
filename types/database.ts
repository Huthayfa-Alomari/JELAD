export type Json = string | number | boolean | null | { [key: string]: Json | undefined } | Json[];
export type Database = {
  public: {
    Tables: {
      landmarks: { Row: { id:string; name_ar:string; name_en:string; city:string; category:string; latitude:number; longitude:number; pickup_instructions:string|null; created_at:string; updated_at:string }; Insert: Partial<Omit<Database["public"]["Tables"]["landmarks"]["Row"],"id"|"created_at"|"updated_at">>; Update: Partial<Database["public"]["Tables"]["landmarks"]["Insert"]> };
      passenger_subscriptions: { Row: { id:string; user_id:string; plan_name:string; route_origin:string; route_destination:string; scheduled_time:string; days_of_week:number[]; start_date:string; end_date:string|null; status:string; created_at:string; updated_at:string }; Insert: Partial<Omit<Database["public"]["Tables"]["passenger_subscriptions"]["Row"],"id"|"created_at"|"updated_at">>; Update: Partial<Database["public"]["Tables"]["passenger_subscriptions"]["Insert"]> };
      corporate_accounts: { Row: { id:string; company_name:string; contact_email:string; credit_limit:number; current_balance:number; billing_cycle:string; created_at:string; updated_at:string }; Insert: Partial<Omit<Database["public"]["Tables"]["corporate_accounts"]["Row"],"id"|"created_at"|"updated_at">>; Update: Partial<Database["public"]["Tables"]["corporate_accounts"]["Insert"]> };
      driver_payouts: { Row: { id:string; driver_id:string; amount:number; payout_method:string; account_number:string; status:string; transaction_ref:string|null; created_at:string; processed_at:string|null }; Insert: Partial<Omit<Database["public"]["Tables"]["driver_payouts"]["Row"],"id"|"created_at">>; Update: Partial<Database["public"]["Tables"]["driver_payouts"]["Insert"]> };
    };
    Functions: {
      verify_trip_start_pin: { Args:{p_job_id:string;p_pin:string}; Returns: unknown };
      get_public_trip_tracking: { Args:{p_share_token:string}; Returns: Json };
      create_sos_incident: { Args:{p_job_id:string;p_description?:string|null}; Returns: unknown };
    };
  };
};
