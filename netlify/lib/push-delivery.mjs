const DEFAULT_LIMIT=100;
const VAPID_PUBLIC_KEY='BImxVQUuI8gXsAJ50jH_pK8KwLeVPEkGlFpWR2DMHhThZl5JKLDpjoSUGgCLIKu4c8VPj7Y5NYXJEQwjUljkj3w';

function clean(value,max=500){
  return String(value||'').replace(/\s+/g,' ').trim().slice(0,max);
}

async function finish(admin,deliveryId,outcome,error=''){
  const {error:finishError}=await admin.rpc('dgie_finalizar_push_delivery',{
    p_delivery_id:deliveryId,
    p_resultado:outcome,
    p_error:clean(error,500)||null
  });
  if(finishError)throw finishError;
}

export async function deliverQueued({
  admin,
  webpush,
  privateKey,
  subject,
  notificationIds=null,
  limit=DEFAULT_LIMIT
}){
  if(!admin||!webpush||!privateKey)throw new Error('El servicio de notificaciones no esta configurado.');
  const ids=Array.isArray(notificationIds)&&notificationIds.length
    ?[...new Set(notificationIds.map(String))]
    :null;
  const {data:deliveries,error:claimError}=await admin.rpc('dgie_reclamar_push_deliveries',{
    p_limite:Math.min(200,Math.max(1,Number(limit)||DEFAULT_LIMIT)),
    p_notificacion_ids:ids
  });
  if(claimError)throw claimError;

  webpush.setVapidDetails(
    subject||'https://dgie.netlify.app',
    VAPID_PUBLIC_KEY,
    privateKey
  );

  const totals={claimed:(deliveries||[]).length,delivered:0,failed:0,stale:0};
  for(const delivery of deliveries||[]){
    const payload=JSON.stringify({
      title:clean(delivery.title,180)||'Nueva notificacion',
      body:clean(delivery.body,300)||'Tenes una novedad en la plataforma.',
      url:clean(delivery.url,500)||'/',
      kind:clean(delivery.kind,30),
      sourceId:clean(delivery.source_id,100),
      unreadCount:Number(delivery.unread_count||0),
      tag:`dgie-${clean(delivery.kind,30)}-${clean(delivery.source_id,100)}`
    });
    try{
      await webpush.sendNotification({
        endpoint:delivery.endpoint,
        keys:{p256dh:delivery.p256dh,auth:delivery.auth}
      },payload,{TTL:604800,urgency:'high'});
      await finish(admin,delivery.delivery_id,'delivered');
      totals.delivered++;
    }catch(error){
      const status=Number(error?.statusCode||0);
      const stale=[404,410].includes(status);
      await finish(admin,delivery.delivery_id,stale?'stale':'failed',error?.message||`HTTP ${status||'desconocido'}`);
      if(stale)totals.stale++;
      else{
        totals.failed++;
        console.error('Push delivery failed',{
          deliveryId:delivery.delivery_id,
          statusCode:status||null,
          message:error?.message
        });
      }
    }
  }
  return totals;
}
