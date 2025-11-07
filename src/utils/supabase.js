import { createClient } from "@supabase/supabase-js";

export const supabaseUrl = import.meta.env.VITE_SUPABASE_URL;
const supabaseKey = import.meta.env.VITE_SUPABASE_ANON_KEY;

// Default client for public/unauthenticated access
export const supabase = createClient(supabaseUrl, supabaseKey);

// Function to create an authenticated client when user logs in
const supabaseClient = async (supabaseAccessToken) => {
  const supabase = createClient(supabaseUrl, supabaseKey, {
    global: {
      headers: {
        Authorization: `Bearer ${supabaseAccessToken}`,
      },
    },
  });

  return supabase;
};

export default supabaseClient;
