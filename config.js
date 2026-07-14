// ---------------------------------------------------------------------------
// SafeCheck-In configuration
// ---------------------------------------------------------------------------
// Leave SUPABASE_URL / SUPABASE_ANON_KEY blank to run in LOCAL mode
// (responses stored only in this browser — good for testing).
//
// Fill them in to switch the whole office into SHARED mode: responses sync
// live across every manager's device through your Supabase project, and a
// passcode is required to open the board.
//
// See SETUP.md for step-by-step instructions.
// ---------------------------------------------------------------------------
window.SAFECHECK_CONFIG = {
  // From Supabase → Project Settings → API
  SUPABASE_URL: "https://wotzqromohcjpstvwvrt.supabase.co",        // e.g. "https://abcd1234.supabase.co"
  SUPABASE_ANON_KEY: "sb_publishable_UetwbySnh2t7GcS7vsQPIg_AJCA0ZrJ",   // the public "anon" key (safe to publish)

  // The shared sign-in you create in Supabase → Authentication → Users.
  // The office PASSCODE is that user's PASSWORD (set/change it in Supabase).
  SHARED_EMAIL: "greg.gearheart@waterboards.ca.gov"
};
