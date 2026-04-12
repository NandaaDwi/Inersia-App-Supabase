import { serve } from "https://deno.land/std@0.168.0/http/server.ts";

const LOCAL_BLACKLIST: string[] = [
  "anjing", "anjir", "anjrit",
  "bangsat", "bgs",
  "bajingan", "bajg",
  "brengsek",
  "keparat",
  "kontol", "kntl", "k0ntol",
  "memek", "mmk",
  "ngentot", "ngnt", "entot",
  "tolol", "tlol",
  "goblok", "gblk",
  "bodoh",
  "babi",
  "sial",
  "kampret",
  "bedebah",
  "asu", "asw",
  "jancok", "jancuk", "cok", "cuk",
  "jangkrik",
  "sialan",
  "tai", "t4i",
  "monyet",
  "bego",
  "dungu",
  "brengsek",
  "celeng",
  "bajingan",
  "fuck", "f*ck", "fck", "f.u.c.k",
  "shit", "sh1t",
  "ass", "a55",
  "bitch", "b1tch",
  "damn",
  "cunt",
  "bastard",
  "idiot",
  "stupid",
  "retard",
  "dick",
  "pussy",
  "cock",
  "nigger", "nigga",
  "whore",
  "slut",
];

function sanitizeText(text: string): string {
  return text
    .toLowerCase()
    .replace(/([a-z0-9])[.\-_*](?=[a-z0-9])/g, "$1")
    .replace(/\s+/g, " ")
    .replace(/3/g, "e")
    .replace(/4/g, "a")
    .replace(/0/g, "o")
    .replace(/1/g, "i")
    .trim();
}

function localCheck(text: string): string[] {
  const lowerText = text.toLowerCase();
  const sanitized = sanitizeText(text);
  const found: string[] = [];
  for (const word of LOCAL_BLACKLIST) {
    const pattern = new RegExp(`(?<![a-zA-Z])${word}(?![a-zA-Z])`, "i");
    if (pattern.test(lowerText) || pattern.test(sanitized)) {
      found.push(word);
    }
  }
  return found;
}

async function openAICheck(
  text: string,
  apiKey: string
): Promise<{ flagged: boolean; categories: string[] }> {
  try {
    const res = await fetch("https://api.openai.com/v1/moderations", {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        Authorization: `Bearer ${apiKey}`,
      },
      body: JSON.stringify({ input: text }),
      signal: AbortSignal.timeout(8000), 
    });

    if (!res.ok) {
      return { flagged: false, categories: [] };
    }

    const data = await res.json();
    const result = data.results?.[0];
    if (!result) return { flagged: false, categories: [] };

    const flaggedCats = Object.entries(result.categories || {})
      .filter(([, v]) => v === true)
      .map(([k]) => translateCategory(k));

    return { flagged: result.flagged === true, categories: flaggedCats };
  } catch {
    return { flagged: false, categories: [] };
  }
}

function translateCategory(key: string): string {
  const map: Record<string, string> = {
    "hate": "ujaran kebencian",
    "hate/threatening": "ancaman kebencian",
    "harassment": "pelecehan",
    "harassment/threatening": "ancaman pelecehan",
    "self-harm": "menyakiti diri",
    "self-harm/intent": "niat menyakiti diri",
    "self-harm/instructions": "instruksi berbahaya",
    "sexual": "konten seksual",
    "sexual/minors": "konten seksual anak",
    "violence": "kekerasan",
    "violence/graphic": "kekerasan grafis",
  };
  return map[key] ?? key;
}


serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response(null, {
      headers: {
        "Access-Control-Allow-Origin": "*",
        "Access-Control-Allow-Methods": "POST",
        "Access-Control-Allow-Headers": "Content-Type, Authorization",
      },
    });
  }

  if (req.method !== "POST") {
    return new Response(
      JSON.stringify({ error: "Method not allowed" }),
      { status: 405, headers: { "Content-Type": "application/json" } }
    );
  }

  try {
    const { text, mode } = await req.json();

    if (!text || typeof text !== "string") {
      return new Response(
        JSON.stringify({ error: "Field 'text' wajib diisi" }),
        { status: 400, headers: { "Content-Type": "application/json" } }
      );
    }

    const isArticleMode = mode === "article";

    const localFound = localCheck(text);
    if (localFound.length > 0 && isArticleMode) {
      return new Response(
        JSON.stringify({
          allowed: false,
          reason: `Konten mengandung kata tidak pantas: ${localFound.slice(0, 3).join(", ")}`,
          layer: "local",
        }),
        { status: 200, headers: { "Content-Type": "application/json" } }
      );
    }

    const apiKey = Deno.env.get("OPENAI_API_KEY") ?? "";
    if (apiKey && isArticleMode) {
      const aiResult = await openAICheck(text, apiKey);
      if (aiResult.flagged) {
        return new Response(
          JSON.stringify({
            allowed: false,
            reason: `Konten tidak dapat dipublikasi: ${aiResult.categories.join(", ")}`,
            layer: "openai",
          }),
          { status: 200, headers: { "Content-Type": "application/json" } }
        );
      }
    }

    let censoredText = text;
    if (!isArticleMode && localFound.length > 0) {
      censoredText = applyCensor(text, localFound);
    }

    return new Response(
      JSON.stringify({
        allowed: true,
        censoredText: isArticleMode ? null : censoredText,
      }),
      { status: 200, headers: { "Content-Type": "application/json" } }
    );
  } catch (e) {
    return new Response(
      JSON.stringify({ error: `Internal error: ${e}` }),
      { status: 500, headers: { "Content-Type": "application/json" } }
    );
  }
});

function applyCensor(text: string, LOCAL_BLACKLIST: string[]): string {
  let result = text;
  for (const word of LOCAL_BLACKLIST) {
    const pattern = new RegExp(
      `(?<![a-zA-Z])${word}(?![a-zA-Z])`,
      "gi"
    );
    result = result.replace(pattern, (m) => "*".repeat(m.length));
  }
  return result;
}