import { createClient } from "@/lib/supabase/server";

const ACTIONS = new Set(["crash","deviation","tamper"]);

function haversineMeters(aLat:number,aLng:number,bLat:number,bLng:number) {
  const R = 6371000;
  const toRad = (v:number) => v * Math.PI / 180;
  const dLat = toRad(bLat-aLat), dLng = toRad(bLng-aLng);
  const x = Math.sin(dLat/2)**2 + Math.cos(toRad(aLat))*Math.cos(toRad(bLat))*Math.sin(dLng/2)**2;
  return 2*R*Math.asin(Math.min(1,Math.sqrt(x)));
}

function pointSegmentDistanceMeters(px:number,py:number,ax:number,ay:number,bx:number,by:number) {
  const latScale = 111320;
  const lngScale = 111320 * Math.cos((py*Math.PI)/180);
  const x=(lon:number)=>lon*lngScale, y=(lat:number)=>lat*latScale;
  const P={x:x(px),y:y(py)}, A={x:x(ax),y:y(ay)}, B={x:x(bx),y:y(by)};
  const dx=B.x-A.x, dy=B.y-A.y;
  if (dx===0 && dy===0) return Math.hypot(P.x-A.x,P.y-A.y);
  const t=Math.max(0,Math.min(1,((P.x-A.x)*dx+(P.y-A.y)*dy)/(dx*dx+dy*dy)));
  return Math.hypot(P.x-(A.x+t*dx),P.y-(A.y+t*dy));
}

function validateLatLng(lat:number,lng:number) {
  return Number.isFinite(lat)&&Number.isFinite(lng)&&lat>=-90&&lat<=90&&lng>=-180&&lng<=180;
}

export async function POST(req: Request) {
  const supabase = await createClient();
  const { data: { user } } = await supabase.auth.getUser();
  if (!user) return Response.json({ error: "Authentication required" }, { status: 401 });

  const b = await req.json().catch(() => ({}));
  const action = String(b.action || "").toLowerCase();
  if (!ACTIONS.has(action)) return Response.json({ error: "Invalid safety engine action" }, { status: 400 });

  if (action === "crash") {
    const impactG = Number(b.impactG);
    if (!Number.isFinite(impactG) || impactG < 0 || impactG > 100) return Response.json({ error: "Invalid impactG" }, { status: 400 });
    const { data, error } = await supabase.rpc("record_crash_event", {
      p_job_id: b.jobId ? String(b.jobId) : null, p_vehicle_id: String(b.vehicleId || ""), p_driver_id: user.id,
      p_impact_g: impactG, p_lat: b.latitude == null ? null : Number(b.latitude), p_lng: b.longitude == null ? null : Number(b.longitude),
      p_metadata: b.metadata || {}
    });
    if (error) return Response.json({ error: error.message }, { status: 400 });
    return Response.json({ crashEventId: data, autoSos: impactG >= 2.5 });
  }

  if (action === "deviation") {
    const lat=Number(b.latitude), lng=Number(b.longitude);
    if (!validateLatLng(lat,lng)) return Response.json({ error:"Valid latitude/longitude required" }, { status:400 });
    const jobId=String(b.jobId||""), vehicleId=String(b.vehicleId||"");
    if (!jobId || !vehicleId) return Response.json({error:"jobId and vehicleId required"},{status:400});

    const { data: job, error: jobError } = await supabase.from("jobs").select("id,driver_id,status").eq("id",jobId).eq("driver_id",user.id).maybeSingle();
    if (jobError || !job) return Response.json({error:"Trip not found or not assigned to you"},{status:403});

    const { data: points, error: pointsError } = await supabase.from("job_route_points")
      .select("seq,latitude,longitude").eq("job_id",jobId).order("seq",{ascending:true}).limit(2000);
    if (pointsError) return Response.json({error:pointsError.message},{status:400});
    if (!points || points.length < 2) return Response.json({error:"No active route geometry is available for this trip"},{status:409});

    let deviationMeters=Number.POSITIVE_INFINITY;
    for(let i=0;i<points.length-1;i++) {
      deviationMeters=Math.min(deviationMeters,pointSegmentDistanceMeters(lat,lng,Number(points[i].latitude),Number(points[i].longitude),Number(points[i+1].latitude),Number(points[i+1].longitude)));
    }
    const seconds=Math.max(0,Math.min(86400,Math.floor(Number(b.durationSeconds)||0)));
    const { data, error } = await supabase.rpc("record_route_deviation", {
      p_job_id:jobId,p_vehicle_id:vehicleId,p_driver_id:user.id,p_deviation_meters:deviationMeters,p_duration_seconds:seconds,
      p_lat:lat,p_lng:lng,p_metadata:{serverComputed:true,routePointCount:points.length}
    });
    if(error) return Response.json({error:error.message},{status:400});
    return Response.json({eventId:data,triggered:Boolean(data),deviationMeters:Math.round(deviationMeters*10)/10,serverComputed:true});
  }

  const { data, error } = await supabase.rpc("record_device_tamper", {
    p_device_id:String(b.deviceId||""),p_vehicle_id:String(b.vehicleId||""),p_job_id:b.jobId?String(b.jobId):null,
    p_tamper_type:String(b.tamperType||"OTHER"),p_lat:b.latitude==null?null:Number(b.latitude),p_lng:b.longitude==null?null:Number(b.longitude),p_metadata:b.metadata||{}
  });
  if(error) return Response.json({error:error.message},{status:400});
  return Response.json({tamperEventId:data});
}
