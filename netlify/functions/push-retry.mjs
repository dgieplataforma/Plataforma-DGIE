import {createClient} from '@supabase/supabase-js';
import webpush from 'web-push';
import {deliverQueued} from '../lib/push-delivery.mjs';

const SUPABASE_URL='https://gvejicxbavveqrrxicen.supabase.co';

function adminClient(secret){
  return createClient(SUPABASE_URL,secret,{
    auth:{persistSession:false,autoRefreshToken:false,detectSessionInUrl:false}
  });
}

export default async ()=>{
  const secret=process.env.SUPABASE_SECRET_KEY||process.env.SUPABASE_SERVICE_ROLE_KEY;
  const privateKey=process.env.VAPID_PRIVATE_KEY;
  if(!secret||!privateKey){
    console.error('Push retry skipped: missing server configuration.');
    return;
  }
  try{
    const totals=await deliverQueued({
      admin:adminClient(secret),
      webpush,
      privateKey,
      subject:process.env.VAPID_SUBJECT||process.env.URL||'https://dgie.netlify.app',
      limit:150
    });
    console.info('Push retry completed',totals);
  }catch(error){
    console.error('Push retry failed',{message:error?.message,code:error?.code});
  }
};

export const config={schedule:'* * * * *'};
