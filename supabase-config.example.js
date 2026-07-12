// supabase-config.example.js
// --------------------------------------------------
// Copy this file to supabase-config.js and fill in your project credentials.
// NEVER commit supabase-config.js with real keys to a public repository.
// Only use the ANON KEY here. Never put the service_role key in browser code.
// --------------------------------------------------

const SUPABASE_URL     = "YOUR_SUPABASE_URL";       // e.g. https://xyzxyz.supabase.co
const SUPABASE_ANON_KEY = "YOUR_SUPABASE_ANON_KEY"; // starts with eyJ...

// UI config
// ---
// Owner access is gated by Supabase Auth (email/password) plus a
// public.profiles row with role = 'owner' for the signed-in user — not by a
// client-side secret. See docs/SECURITY_OWNER_AUTH_SETUP.md to provision an
// owner account. There is no OWNER_PIN or client-side owner secret anymore.

// Employee identifier used to filter stock units for the employee view.
// In a real auth setup this would come from the authenticated session.
// For now set this to the employee_code or employee UUID you want to show.
const DEFAULT_EMPLOYEE_CODE = "EMP-001";
