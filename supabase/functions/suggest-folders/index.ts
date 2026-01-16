
import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2';

const corsHeaders = {
    'Access-Control-Allow-Origin': '*',
    'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
};

serve(async (req) => {
    if (req.method === 'OPTIONS') {
        return new Response('ok', { headers: corsHeaders });
    }

    try {
        const { caption, device_id } = await req.json();
        console.log("SUGGEST-FOLDERS called with caption:", caption);

        // Init Supabase Client for Logging
        const supabaseUrl = Deno.env.get('SUPABASE_URL')!;
        const supabaseKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!;
        const supabase = createClient(supabaseUrl, supabaseKey);

        // LOG: backend_received
        await supabase.from("debug_events").insert({
            device_id,
            stage: "backend_received",
            payload: { caption }
        });

        if (!caption || typeof caption !== 'string' || caption.trim().length === 0) {
            return new Response(JSON.stringify({ suggestions: [] }), {
                headers: { ...corsHeaders, 'Content-Type': 'application/json' }
            });
        }

        // AI Classification via RAW FETCH (Reusing generic pattern from classify-folder)
        const apiKey = Deno.env.get('GEMINI_API_KEY');
        if (!apiKey) throw new Error("GEMINI_API_KEY is not set");

        // Reusing exact model from existing codebase
        const GEMINI_URL = `https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash-lite:generateContent?key=${apiKey}`;

        const promptText = `
      Suggest 2-3 concise folder names for saving a link with this caption.
      Caption: "${caption}"
      Rules:
      1. Return JSON array of strings ONLY. Example: ["Food", "Travel"]
      2. Max 3 suggestions.
      3. Capitalized, clean strings (no emojis).
      4. Single word or short phrase categories.
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
            console.error(`Gemini API Error: ${response.status} ${errText}`);
            // Fallback to empty list on error to be safe
            return new Response(JSON.stringify({ suggestions: [] }), {
                headers: { ...corsHeaders, 'Content-Type': 'application/json' },
            });
        }

        const data = await response.json();
        const text = data?.candidates?.[0]?.content?.parts?.[0]?.text?.trim();

        let suggestions: string[] = [];
        if (text) {
            // Clean up markdown code blocks if Gemini returns them
            const cleanText = text.replace(/```json/g, '').replace(/```/g, '').trim();
            try {
                const parsed = JSON.parse(cleanText);
                if (Array.isArray(parsed)) {
                    suggestions = parsed.map(s => String(s).trim()).filter(s => s.length > 0);
                }
            } catch (e) {
                console.error('Error parsing Gemini response:', e);
                // Fallback or simple split if not JSON
                // suggestions = [];
            }
        }

        // Limit to 3 and unique
        suggestions = [...new Set(suggestions)].slice(0, 3);
        console.log("SUGGEST-FOLDERS Gemini output:", suggestions);

        // LOG: backend_gemini_response
        await supabase.from("debug_events").insert({
            device_id,
            stage: "backend_gemini_response",
            payload: { suggestions }
        });

        return new Response(JSON.stringify({ suggestions }), {
            headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        });

    } catch (error) {
        console.error("SUGGEST-FOLDERS error:", error);

        // Try logging error if possible (might fail if supabase client not init, but worth a try if it was)
        try {
            const supabaseUrl = Deno.env.get('SUPABASE_URL')!;
            const supabaseKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!;
            const supabase = createClient(supabaseUrl, supabaseKey);
            await supabase.from("debug_events").insert({
                device_id: (req as any)._debug_device_id, // we might not have it in catch, but ok to skip or try
                stage: "backend_error",
                payload: { error: error.message }
            });
        } catch (_) { }

        return new Response(JSON.stringify({ error: error.message, suggestions: [] }), {
            status: 200, // Return 200 with empty suggestions to degrade gracefully
            headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        });
    }
});
