
import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2.45.0';

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
};

serve(async (req) => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders });
  }

  try {
    // 1. Init Supabase Client (Admin)
    const supabaseUrl = Deno.env.get('SUPABASE_URL')!;
    const supabaseKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!; // Use Service Role for admin access
    const supabase = createClient(supabaseUrl, supabaseKey);

    // 2. Fetch Batch of Unclassified Folders
    const { data: folders, error: fetchError } = await supabase
      .from('folders')
      .select('id, name')
      .is('system_category', null)
      .limit(20); // Process 20 at a time to avoid timeout

    if (fetchError) throw fetchError;
    if (!folders || folders.length === 0) {
      return new Response(JSON.stringify({ message: "No unclassified folders found.", processed: 0 }), {
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      });
    }

    // 3. Init Gemini Config
    const geminiKey = Deno.env.get('GEMINI_API_KEY');
    if (!geminiKey) throw new Error("GEMINI_API_KEY not set");

    // USING RAW FETCH TO FORCE v1 API
    const GEMINI_URL = `https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash-lite:generateContent?key=${geminiKey}`;

    let processedCount = 0;
    const failures: any[] = [];

    // 4. Process Each Folder
    for (const folder of folders) {
      // Fetch context (links)
      const { data: links } = await supabase
        .from('saved_links')
        .select('title')
        .eq('folder_id', folder.id)
        .limit(5);

      const captions = links?.map(l => l.title) || [];

      // AI Classification
      try {
        const promptText = `
          Classify this folder into ONE category.
          Folder: "${folder.name}"
          Contents: ${JSON.stringify(captions)}
          Rules: One word/phrase only. If unclear, "Other".
        `;

        const response = await fetch(GEMINI_URL, {
          method: 'POST',
          headers: { 'Content-Type': 'application/json' },
          body: JSON.stringify({
            contents: [{
              parts: [{ text: promptText }]
            }]
          })
        });

        if (!response.ok) {
          const errText = await response.text();
          throw new Error(`Gemini API Error: ${response.status} ${errText}`);
        }

        const data = await response.json();
        // Extract text safely
        const category = data?.candidates?.[0]?.content?.parts?.[0]?.text?.trim();

        // Update DB
        if (category) {
          await supabase
            .from('folders')
            .update({ system_category: category })
            .eq('id', folder.id);
          processedCount++;
        } else {
          throw new Error("No category returned by AI");
        }
      } catch (e) {
        console.error(`Failed to classify folder ${folder.id}:`, e);
        failures.push({ folderId: folder.id, error: e.message || e });
      }
    }

    return new Response(JSON.stringify({
      message: "Batch complete",
      processed: processedCount,
      remaining: folders.length - processedCount,
      failures: failures
    }), {
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    });

  } catch (error) {
    return new Response(JSON.stringify({ error: error.message }), {
      status: 500,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    });
  }
});
