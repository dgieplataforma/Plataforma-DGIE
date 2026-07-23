import { createClient } from '@supabase/supabase-js';
import webpush from 'web-push';
import { deliverQueued } from '../lib/push-delivery.mjs';

const SUPABASE_URL='https://gvejicxbavveqrrxicen.supabase.co';
const ALLOWED_KINDS=new Set(['comunicado','reclamo']);

function json(body,status=200){
  return Response.json(body,{status,headers:{'Cache-Control':'no-store'}});
}
function clean(value,max=180){
  return String(value||'').replace(/\s+/g,' ').trim().slice(0,max);
}
function normalizedRole(value){
  return clean(value,40).toLowerCase();
}
function numericZones(value){
  return (Array.isArray(value)?value:[]).map(Number).filter(zone=>zone>=1&&zone<=17);
}
function bearerToken(request){
  const header=request.headers.get('authorization')||'';
  return header.toLowerCase().startsWith('bearer ')?header.slice(7).trim():'';
}
function serverClient(secret){
  return createClient(SUPABASE_URL,secret,{
    auth:{persistSession:false,autoRefreshToken:false,detectSessionInUrl:false}
  });
}
function canDispatchCommunication(profile,communication){
  const role=normalizedRole(profile?.rol);
  const scope=clean(communication?.alcance,40);
  const zones=numericZones(communication?.zonas);
  if(['coordinador','director'].includes(role))return true;
  if(role!=='inspector'||!['empresa_zona','coordinador'].includes(scope))return false;
  return zones.length===1&&zones[0]===Number(profile?.zona||0);
}
function canDispatchClaim(profile,claim){
  const role=normalizedRole(profile?.rol);
  if(['callcenter','coordinador','director'].includes(role))return true;
  return role==='inspector'&&Number(profile?.zona||0)===Number(claim?.zona||0);
}
function recipientsForCommunication(profiles,communication){
  const scope=clean(communication?.alcance,40);
  const zones=new Set(numericZones(communication?.zonas));
  const metadata=communication?.encuesta?.meta||{};
  const recipients=profiles.filter(profile=>{
    const role=normalizedRole(profile?.rol);
    const zone=Number(profile?.zona||0);
    if(scope==='general')return role==='inspector';
    if(scope==='zona')return role==='inspector'&&zones.has(zone);
    if(scope==='empresas')return role==='empresa';
    if(scope==='empresa_zona')return role==='empresa'&&zones.has(zone);
    if(scope==='coordinador')return role==='coordinador';
    return false;
  });
  if(metadata.copiaCoordinacion===true){
    profiles.filter(profile=>normalizedRole(profile?.rol)==='coordinador').forEach(profile=>recipients.push(profile));
  }
  return recipients;
}
async function loadEvent(admin,kind,sourceId,userId){
  if(kind==='comunicado'){
    const {data,error}=await admin.from('comunicaciones')
      .select('id,tipo,titulo,mensaje,alcance,zonas,creado_por,creado_por_nombre,encuesta')
      .eq('id',sourceId).maybeSingle();
    if(error)throw error;
    if(!data)return {error:json({error:'La comunicacion no existe.'},404)};
    if(String(data.creado_por||'')!==String(userId))return {error:json({error:'No podes emitir esta comunicacion.'},403)};
    return {record:data};
  }
  const {data,error}=await admin.from('reclamos')
    .select('id,numero,titulo,descripcion,zona,establecimiento_id,creado_por')
    .eq('id',sourceId).maybeSingle();
  if(error)throw error;
  if(!data)return {error:json({error:'El reclamo no existe.'},404)};
  if(String(data.creado_por||'')!==String(userId))return {error:json({error:'No podes emitir este reclamo.'},403)};
  return {record:data};
}
async function notificationContent(admin,kind,record){
  if(kind==='comunicado'){
    return {
      title:'Nuevo comunicado',
      body:clean(record.titulo||record.mensaje||'Tenes un nuevo comunicado.'),
      url:'/?dgiePush=comunicado&sourceId='+encodeURIComponent(record.id)
    };
  }
  let establishment='';
  if(record.establecimiento_id){
    const {data}=await admin.from('establecimientos').select('nombre').eq('id',record.establecimiento_id).maybeSingle();
    establishment=clean(data?.nombre,90);
  }
  const detail=clean(record.titulo||record.descripcion||'Nuevo reclamo',120);
  return {
    title:`Nuevo reclamo - Zona ${Number(record.zona)||''}`.trim(),
    body:clean([establishment,detail].filter(Boolean).join(': ')),
    url:'/?dgiePush=reclamo&sourceId='+encodeURIComponent(record.id)
  };
}
export default async request=>{
  if(request.method!=='POST')return json({error:'Metodo no permitido.'},405);
  const secret=process.env.SUPABASE_SECRET_KEY||process.env.SUPABASE_SERVICE_ROLE_KEY;
  const privateKey=process.env.VAPID_PRIVATE_KEY;
  if(!secret||!privateKey)return json({error:'El servicio de notificaciones no esta configurado.'},503);

  let input;
  try{input=await request.json()}catch(_){return json({error:'Solicitud invalida.'},400)}
  const kind=clean(input?.kind,30);
  const sourceId=clean(input?.sourceId,100);
  if(!ALLOWED_KINDS.has(kind)||!sourceId)return json({error:'Datos incompletos.'},400);
  const token=bearerToken(request);
  if(!token)return json({error:'Falta autenticacion.'},401);

  const admin=serverClient(secret);
  const {data:userData,error:userError}=await admin.auth.getUser(token);
  const authUser=userData?.user;
  if(userError||!authUser)return json({error:'La sesion no es valida.'},401);

  try{
    const [{data:profile,error:profileError},eventResult]=await Promise.all([
      admin.from('perfiles').select('id,rol,zona,nombre').eq('id',authUser.id).maybeSingle(),
      loadEvent(admin,kind,sourceId,authUser.id)
    ]);
    if(profileError)throw profileError;
    if(!profile)return json({error:'No se encontro el perfil.'},403);
    if(eventResult.error)return eventResult.error;
    const record=eventResult.record;
    if(kind==='comunicado'&&!canDispatchCommunication(profile,record))return json({error:'El perfil no puede emitir este comunicado.'},403);
    if(kind==='reclamo'&&!canDispatchClaim(profile,record))return json({error:'El perfil no puede emitir este reclamo.'},403);

    const {data:profiles,error:profilesError}=await admin.from('perfiles').select('id,rol,zona');
    if(profilesError)throw profilesError;
    const recipients=kind==='comunicado'
      ?recipientsForCommunication(profiles||[],record)
      :(profiles||[]).filter(item=>normalizedRole(item.rol)==='inspector'&&Number(item.zona||0)===Number(record.zona||0));
    const recipientIds=[...new Set(recipients.map(item=>String(item.id)).filter(id=>id&&id!==String(authUser.id)))];
    if(!recipientIds.length)return json({ok:true,recipients:0,delivered:0,failed:0});

    const content=await notificationContent(admin,kind,record);
    const rows=recipientIds.map(userId=>({
      user_id:userId,
      kind,
      source_id:String(record.id),
      title:content.title,
      body:content.body,
      url:content.url
    }));
    const {error:insertError}=await admin.from('push_notifications').upsert(rows,{
      onConflict:'user_id,kind,source_id',ignoreDuplicates:true
    });
    if(insertError)throw insertError;
    const {data:notifications,error:notificationsError}=await admin.from('push_notifications')
      .select('id')
      .eq('kind',kind)
      .eq('source_id',String(record.id))
      .in('user_id',recipientIds);
    if(notificationsError)throw notificationsError;

    const totals=await deliverQueued({
      admin,
      webpush,
      privateKey,
      subject:process.env.VAPID_SUBJECT||process.env.URL||'https://dgie.netlify.app',
      notificationIds:(notifications||[]).map(item=>item.id),
      limit:200
    });
    return json({ok:true,recipients:recipientIds.length,...totals});
  }catch(error){
    console.error('Push dispatch error',{message:error?.message,code:error?.code});
    return json({error:'No se pudo emitir la notificacion.'},500);
  }
};

export const config={path:'/api/push/dispatch'};
