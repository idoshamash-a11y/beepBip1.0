// Permissive CORS headers used by every Edge Function the Flutter client
// calls directly. Tighten the origin list once we run a proper web build —
// for now the app is mobile-only and we want preflights to succeed from any
// host (including local emulators / staging URLs).
export const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
};
