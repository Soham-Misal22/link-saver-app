
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
    const payload = await req.json();

    // Init Supabase Admin
    const supabaseUrl = Deno.env.get('SUPABASE_URL')!;
    const supabaseKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!;
    const supabase = createClient(supabaseUrl, supabaseKey);

    let folderId: number | null = null;
    let folderName: string | null = null;

    // Handle Database Webhook Payload
    if (payload.record && payload.table) {
      if (payload.table === 'folders') {
        folderId = payload.record.id;
        folderName = payload.record.name;
        if (payload.record.system_category) {
          return new Response(JSON.stringify({ message: "Already classified" }), { headers: corsHeaders });
        }
      } else if (payload.table === 'saved_links') {
        folderId = payload.record.folder_id;
        if (!folderId) {
          return new Response(JSON.stringify({ message: "No folder_id" }), { headers: corsHeaders });
        }

        const { data: folder, error } = await supabase
          .from('folders')
          .select('id, name, system_category')
          .eq('id', folderId)
          .single();

        if (error || !folder) throw new Error("Folder not found");
        if (folder.system_category) {
          return new Response(JSON.stringify({ message: "Already classified" }), { headers: corsHeaders });
        }
        folderName = folder.name;
      }
    } else if (payload.folderName) {
      folderName = payload.folderName;
    }

    if (!folderId || !folderName) {
      return new Response(JSON.stringify({ message: "Ignored: Invalid payload" }), {
        headers: { ...corsHeaders, 'Content-Type': 'application/json' }
      });
    }

    // Fetch Captions (Context)
    const { data: links } = await supabase
      .from('saved_links')
      .select('title')
      .eq('folder_id', folderId)
      .limit(5);

    const captions = links?.map(l => l.title) || [];

    // AI Classification via RAW FETCH
    const apiKey = Deno.env.get('GEMINI_API_KEY');
    if (!apiKey) throw new Error("GEMINI_API_KEY is not set");

    const GEMINI_URL = `https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash-lite:generateContent?key=${apiKey}`;

    const promptText = `
      Classify this folder into ONE category.
      Folder: "${folderName}"
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
    const category = data?.candidates?.[0]?.content?.parts?.[0]?.text?.trim();

    // Update Database
    if (category) {
      await supabase
        .from('folders')
        .update({ system_category: category })
        .eq('id', folderId);
    }

    return new Response(JSON.stringify({ category, updated: true }), {
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    });

  } catch (error) {
    return new Response(JSON.stringify({ error: error.message }), {
      status: 500,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    });
  }
});
