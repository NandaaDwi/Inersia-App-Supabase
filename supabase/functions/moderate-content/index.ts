import { serve } from "https://deno.land/std@0.168.0/http/server.ts";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
  "Access-Control-Allow-Headers": "Content-Type, Authorization, apikey",
};

async function openaiCheck(text: string, apiKey: string) {
  const res = await fetch("https://api.openai.com/v1/moderations", {
    method: "POST",
    headers: {
      "Content-Type": "application/json",
      Authorization: `Bearer ${apiKey}`,
    },
    body: JSON.stringify({ input: text }),
  });

  if (!res.ok) throw new Error("OpenAI API Error");
  const data = await res.json();
  return data.results?.[0];
}

serve(async (req) => {
  if (req.method === "OPTIONS") return new Response(null, { headers: corsHeaders });

  try {
    const { text } = await req.json();
    if (!text) return new Response(JSON.stringify({ error: "No text" }), { status: 400 });

    const apiKey = Deno.env.get("OPENAI_API_KEY");
    if (!apiKey) return new Response(JSON.stringify({ error: "No API Key" }), { status: 500 });

    const result = await openaiCheck(text, apiKey);

    if (result.flagged) {
      const categories = Object.entries(result.categories)
        .filter(([_, v]) => v)
        .map(([k]) => k);

      return new Response(JSON.stringify({
        allowed: false,
        reason: `Konten melanggar kebijakan OpenAI: ${categories.join(", ")}`,
      }), { headers: { ...corsHeaders, "Content-Type": "application/json" } });
    }

    return new Response(JSON.stringify({ allowed: true }), { 
      headers: { ...corsHeaders, "Content-Type": "application/json" } 
    });

  } catch (err) {
    return new Response(JSON.stringify({ error: err.message }), { 
      status: 500, 
      headers: corsHeaders 
    });
  }
});