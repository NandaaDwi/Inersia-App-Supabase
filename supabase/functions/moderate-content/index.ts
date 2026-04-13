
import { serve } from "https://deno.land/std@0.168.0/http/server.ts";

// ── Cors headers ─────────────────────────────────────────────
const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
  "Access-Control-Allow-Headers": "Content-Type, Authorization, apikey",
};

function json(body: unknown, status = 200) {
  return new Response(JSON.stringify(body), {
    status,
    headers: { ...corsHeaders, "Content-Type": "application/json" },
  });
}

const ID_BLACKLIST = [
  "anjing","anjir","anjrit","anjer",
  "bangsat","bajingan","brengsek","keparat",
  "ngentot","entot","memek","kontol",
  "tolol","goblok","kampret","bedebah",
  "jancok","jancuk","sialan","monyet",
  "bego","dungu","celeng","asu","tai",
  "kntl","mmk","ngnt","bgs","bajg",
];

const EN_BLACKLIST = [
  "fuck","shit","bitch","cunt","bastard",
  "asshole","motherfucker","nigger","nigga",
  "whore","slut","retard","pussy","cock","dick",
];

function sanitize(text: string): string {
  return text
    .toLowerCase()
    .replace(/([a-z0-9])[.\-_*+|](?=[a-z0-9])/g, "$1")
    .replace(/4/g,"a").replace(/3/g,"e").replace(/1/g,"i")
    .replace(/0/g,"o").replace(/5/g,"s").replace(/@/g,"a")
    .replace(/(.)\1{2,}/g, (_, c) => c.repeat(2))
    .replace(/\s+/g, " ").trim();
}

function localCheck(text: string): string | null {
  const lower = text.toLowerCase();
  const norm  = sanitize(text);

  for (const w of ID_BLACKLIST) {
    if (lower.includes(w) || norm.includes(w)) return w;
  }

  for (const w of EN_BLACKLIST) {
    const re = new RegExp(`(?<![a-z])${w}(?![a-z])`, "i");
    if (re.test(lower) || re.test(norm)) return w;
  }

  return null;
}

async function openaiCheck(text: string, apiKey: string) {
  const res = await fetch("https://api.openai.com/v1/moderations", {
    method: "POST",
    headers: {
      "Content-Type": "application/json",
      Authorization: `Bearer ${apiKey}`,
    },
    body: JSON.stringify({ input: text }),
    signal: AbortSignal.timeout(8000),
  });

  if (!res.ok) return { flagged: false, categories: [] as string[] };

  const data = await res.json();
  const result = data.results?.[0];
  if (!result) return { flagged: false, categories: [] as string[] };

  const flaggedCats = Object.entries(result.categories as Record<string,boolean>)
    .filter(([, v]) => v)
    .map(([k]) => k);

  return { flagged: result.flagged as boolean, categories: flaggedCats };
}

function censor(text: string): string {
  let r = text;
  for (const w of ID_BLACKLIST) {
    r = r.replace(new RegExp(w, "gi"), m => "*".repeat(m.length));
  }
  for (const w of EN_BLACKLIST) {
    r = r.replace(
      new RegExp(`(?<![a-zA-Z])${w}(?![a-zA-Z])`, "gi"),
      m => "*".repeat(m.length),
    );
  }
  return r;
}

serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response(null, { headers: corsHeaders });
  }
  if (req.method !== "POST") {
    return json({ error: "Method not allowed" }, 405);
  }

  let body: { text?: string; mode?: string };
  try {
    body = await req.json();
  } catch {
    return json({ error: "Invalid JSON" }, 400);
  }

  const { text, mode } = body;
  if (!text || typeof text !== "string" || text.trim().length === 0) {
    return json({ error: "Field 'text' wajib diisi" }, 400);
  }

  const isArticle = mode === "article";

  const bad = localCheck(text);
  if (bad) {
    if (isArticle) {
      return json({ allowed: false, reason: "Konten mengandung kata tidak pantas.", layer: "local" });
    }
    return json({ allowed: true, censoredText: censor(text) });
  }

  if (isArticle) {
    const apiKey = Deno.env.get("OPENAI_API_KEY") ?? "";
    if (apiKey) {
      try {
        const { flagged, categories } = await openaiCheck(text, apiKey);
        if (flagged) {
          return json({
            allowed: false,
            reason: `Konten melanggar: ${categories.join(", ")}`,
            layer: "openai",
          });
        }
      } catch {
      }
    }
  }

  return json({ allowed: true, censoredText: isArticle ? null : text });
});