import { createClient } from '@supabase/supabase-js';
import webpush from 'web-push';
import { deliverQueued } from '../lib/push-delivery.mjs';

const SUPABASE_URL='https://gvejicxbavveqrrxicen.supabase.co';
const ALLOWED_KINDS=new Set(['comunicado','reclamo','certificado','comentario_intervencion','comentario_relevamiento']);

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
function normalizedName(value){
  return clean(value,180).normalize('NFD').replace(/[\u0300-\u036f]/g,'').toLowerCase();
}
function sourceParts(value){
  const source=clean(value,100);
  const separator=source.indexOf(':');
  return separator>0
    ?{recordId:source.slice(0,separator),eventKey:source.slice(separator+1)}
    :{recordId:source,eventKey:''};
}
function commentsForRecord(kind,record){
  if(kind==='comentario_intervencion')return Array.isArray(record?.comentarios_coordinacion)?record.comentarios_coordinacion:[];
  const data=record?.datos&&typeof record.datos==='object'?record.datos:{};
  return Array.isArray(data.comentariosCoordinacion)
    ?data.comentariosCoordinacion
    :(Array.isArray(data.comentarios_coordinacion)?data.comentarios_coordinacion:[]);
}
function findCommentEvent(kind,record,eventKey){
  if(!eventKey)return null;
  for(const comment of commentsForRecord(kind,record)){
    if(String(comment?.fecha||'')===eventKey){
      return {type:'comment',author:clean(comment?.autor||'Usuario',120),text:clean(comment?.texto||'',300)};
    }
    for(const response of Array.isArray(comment?.respuestas)?comment.respuestas:[]){
      if(String(response?.fecha||'')===eventKey){
        return {type:'response',author:clean(response?.autor||'Usuario',120),text:clean(response?.texto||'',300)};
      }
    }
  }
  return null;
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
function authorMatches(profile,event){
  const profileName=normalizedName(profile?.nombre);
  const authorName=normalizedName(event?.author);
  return !profileName||!authorName||profileName===authorName;
}
function canDispatchCertificate(profile,certificate){
  const role=normalizedRole(profile?.rol);
  if(role!=='empresa'||Number(profile?.zona||0)!==Number(certificate?.zona||0))return false;
  const createdBy=normalizedName(certificate?.creado_por);
  const profileName=normalizedName(profile?.nombre);
  return !createdBy||!profileName||createdBy===profileName;
}
function canDispatchComment(profile,record,event){
  if(!event||!authorMatches(profile,event))return false;
  const role=normalizedRole(profile?.rol);
  if(['coordinador','director','direccion'].includes(role))return true;
  return role==='inspector'&&Number(profile?.zona||0)===Number(record?.zona||0);
}
function recipientsForEvent(profiles,kind,record,senderProfile){
  const zone=Number(record?.zona||0);
  if(kind==='certificado'||normalizedRole(senderProfile?.rol)!=='inspector'){
    return profiles.filter(profile=>normalizedRole(profile?.rol)==='inspector'&&Number(profile?.zona||0)===zone);
  }
  return profiles.filter(profile=>normalizedRole(profile?.rol)==='coordinador');
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
  const parts=sourceParts(sourceId);
  if(kind==='comunicado'){
    const {data,error}=await admin.from('comunicaciones')
      .select('id,tipo,titulo,mensaje,alcance,zonas,creado_por,creado_por_nombre,encuesta')
      .eq('id',parts.recordId).maybeSingle();
    if(error)throw error;
    if(!data)return {error:json({error:'La comunicacion no existe.'},404)};
    if(String(data.creado_por||'')!==String(userId))return {error:json({error:'No podes emitir esta comunicacion.'},403)};
    return {record:data};
  }
  if(kind==='reclamo'){
    const {data,error}=await admin.from('reclamos')
    .select('id,numero,titulo,descripcion,zona,establecimiento_id,creado_por')
    .eq('id',parts.recordId).maybeSingle();
  if(error)throw error;
  if(!data)return {error:json({error:'El reclamo no existe.'},404)};
  if(String(data.creado_por||'')!==String(userId))return {error:json({error:'No podes emitir este reclamo.'},403)};
  return {record:data};
  }
  if(kind==='certificado'){
    const {data,error}=await admin.from('certificados_medicion')
      .select('id,zona,establecimiento_id,establecimiento_nombre,archivo_original,creado_por,created_at')
      .eq('id',parts.recordId).maybeSingle();
    if(error)throw error;
    if(!data)return {error:json({error:'El certificado no existe.'},404)};
    return {record:data};
  }
  const intervention=kind==='comentario_intervencion';
  const table=intervention?'intervenciones':'relevamientos';
  const fields=intervention
    ?'id,zona,establecimiento_id,comentarios_coordinacion'
    :'id,zona,establecimiento_id,datos';
  const {data,error}=await admin.from(table)
    .select(fields)
    .eq('id',parts.recordId).maybeSingle();
  if(error)throw error;
  if(!data)return {error:json({error:intervention?'La intervencion no existe.':'El relevamiento no existe.'},404)};
  const event=findCommentEvent(kind,data,parts.eventKey);
  if(!event)return {error:json({error:'El comentario no existe.'},404)};
  return {record:data,event};
}
async function notificationContent(admin,kind,record,sourceId,event){
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
  if(kind==='certificado'){
    const name=clean(record.establecimiento_nombre||establishment||'Establecimiento',100);
    return {
      title:`Nuevo certificado - Zona ${Number(record.zona)||''}`.trim(),
      body:clean([name,record.archivo_original||'Certificado pendiente de revision'].filter(Boolean).join(': '),300),
      url:'/?dgiePush=certificado&sourceId='+encodeURIComponent(sourceId)
    };
  }
  if(kind==='comentario_intervencion'||kind==='comentario_relevamiento'){
    const label=kind==='comentario_intervencion'?'intervencion':'relevamiento';
    const title=event?.type==='response'?`Nueva respuesta en ${label}`:`Nuevo comentario en ${label}`;
    return {
      title,
      body:clean([establishment,event?.author,event?.text].filter(Boolean).join(': '),300),
      url:`/?dgiePush=${kind}&sourceId=`+encodeURIComponent(sourceId)
    };
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
    const event=eventResult.event||null;
    if(kind==='comunicado'&&!canDispatchCommunication(profile,record))return json({error:'El perfil no puede emitir este comunicado.'},403);
    if(kind==='reclamo'&&!canDispatchClaim(profile,record))return json({error:'El perfil no puede emitir este reclamo.'},403);
    if(kind==='certificado'&&!canDispatchCertificate(profile,record))return json({error:'El perfil no puede emitir este certificado.'},403);
    if(kind.startsWith('comentario_')&&!canDispatchComment(profile,record,event))return json({error:'El perfil no puede emitir este comentario.'},403);

    const {data:profiles,error:profilesError}=await admin.from('perfiles').select('id,rol,zona');
    if(profilesError)throw profilesError;
    const recipients=kind==='comunicado'
      ?recipientsForCommunication(profiles||[],record)
      :kind==='reclamo'
        ?(profiles||[]).filter(item=>normalizedRole(item.rol)==='inspector'&&Number(item.zona||0)===Number(record.zona||0))
        :recipientsForEvent(profiles||[],kind,record,profile);
    const recipientIds=[...new Set(recipients.map(item=>String(item.id)).filter(id=>id&&id!==String(authUser.id)))];
    if(!recipientIds.length)return json({ok:true,recipients:0,delivered:0,failed:0});

    const content=await notificationContent(admin,kind,record,sourceId,event);
    const rows=recipientIds.map(userId=>({
      user_id:userId,
      kind,
      source_id:String(sourceId),
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
      .eq('source_id',String(sourceId))
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
