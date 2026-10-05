import {createClient} from "@/lib/supabase/server";

export async function POST(req:Request){
 const supabase=await createClient();
 const {data:{user}}=await supabase.auth.getUser();
 if(!user)return Response.json({error:"Authentication required"},{status:401});
 const b=await req.json();
 const deviceId=String(b.deviceId||""); const vehicleId=String(b.vehicleId||"");
 if(!deviceId||!vehicleId||typeof b.latitude!=="number"||typeof b.longitude!=="number")return Response.json({error:"deviceId, vehicleId, latitude and longitude are required"},{status:400});
 const {data:driver}=await supabase.from("drivers").select("id").eq("user_id",user.id).maybeSingle();
 if(!driver)return Response.json({error:"Driver account required"},{status:403});
 const {data:vehicle}=await supabase.from("vehicles").select("id,driver_id").eq("id",vehicleId).eq("driver_id",driver.id).maybeSingle();
 if(!vehicle)return Response.json({error:"Vehicle access denied"},{status:403});
 const {data, error}=await supabase.rpc("record_device_telemetry",{p_device_id:deviceId,p_vehicle_id:vehicleId,p_job_id:b.jobId||null,p_lat:b.latitude,p_lng:b.longitude,p_speed:b.speedKmh??null,p_heading:b.heading??null,p_accuracy:b.accuracyM??null,p_battery:b.batteryPercent??null,p_ignition:b.ignitionOn??null,p_motion:b.motionDetected??null});
 if(error)return Response.json({error:error.message},{status:400});
 const speed=Number(b.speedKmh||0);
 if(speed>=120){
  await supabase.from("safety_events").insert({job_id:b.jobId||null,vehicle_id:vehicleId,driver_id:driver.id,event_type:"SPEED_ALERT",severity:speed>=150?"CRITICAL":"HIGH",latitude:b.latitude,longitude:b.longitude,metadata:{speed_kmh:speed}});
 }
 return Response.json({telemetryId:data});
}