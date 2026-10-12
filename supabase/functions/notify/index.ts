// Lotus – Push-Benachrichtigungen über Firebase Cloud Messaging (HTTP v1).
//
// Wird von Supabase Database Webhooks aufgerufen:
//   * INSERT auf public.messages          → "Neue Nachricht von …" an die andere Person
//   * INSERT/UPDATE auf public.matches    → "Neues Match" bzw. "Euer Chat ist jetzt offen"
//
// Benötigte Secrets (supabase secrets set …):
//   FIREBASE_SERVICE_ACCOUNT  JSON des Firebase-Service-Accounts
//   NOTIFY_WEBHOOK_SECRET     gleicher Wert wie im Header "x-webhook-secret" des Webhooks
// SUPABASE_URL und SUPABASE_SERVICE_ROLE_KEY stellt Supabase automatisch bereit.
//
// Datenschutz: Benachrichtigungen enthalten nie den Nachrichtentext, nur den Vornamen.

import { createClient } from "npm:@supabase/supabase-js@2.45.4";

type WebhookPayload = {
  type: "INSERT" | "UPDATE" | "DELETE";
  table: string;
  record: Record<string, unknown> | null;
  old_record: Record<string, unknown> | null;
};

type Notification = { userId: string; title: string; body: string; data: Record<string, string> };

type ServiceAccount = { client_email: string; private_key: string; project_id: string };

const supabase = createClient(
  Deno.env.get("SUPABASE_URL")!,
  Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!,
);

Deno.serve(async (req) => {
  if (req.headers.get("x-webhook-secret") !== Deno.env.get("NOTIFY_WEBHOOK_SECRET")) {
    return new Response("unauthorized", { status: 401 });
  }

  const payload = (await req.json()) as WebhookPayload;
  const notifications = await buildNotifications(payload);
  if (notifications.length === 0) {
    return Response.json({ sent: 0 });
  }

  const serviceAccount = JSON.parse(Deno.env.get("FIREBASE_SERVICE_ACCOUNT")!) as ServiceAccount;
  const accessToken = await getAccessToken(serviceAccount);
  let sent = 0;
  for (const notification of notifications) {
    sent += await sendToUser(serviceAccount.project_id, accessToken, notification);
  }
  return Response.json({ sent });
});

async function buildNotifications(payload: WebhookPayload): Promise<Notification[]> {
  const record = payload.record;
  if (!record) return [];

  if (payload.table === "messages" && payload.type === "INSERT") {
    const { data: match } = await supabase
      .from("matches")
      .select("id, user_a, user_b")
      .eq("id", record.match_id)
      .single();
    if (!match) return [];
    const recipient = match.user_a === record.sender_id ? match.user_b : match.user_a;
    const senderName = await displayName(record.sender_id as string);
    return [{
      userId: recipient,
      title: "Neue Nachricht",
      body: `${senderName} hat dir geschrieben.`,
      data: { type: "message", match_id: match.id },
    }];
  }

  if (payload.table === "matches") {
    const isNew = payload.type === "INSERT";
    // Ein Match aus der Warteschlange wurde freigeschaltet
    const unlocked = payload.type === "UPDATE" && record.state === "active" &&
      payload.old_record?.state === "queued";
    if (isNew || unlocked) {
      const userA = record.user_a as string;
      const userB = record.user_b as string;
      const [nameA, nameB] = await Promise.all([displayName(userA), displayName(userB)]);
      const title = isNew ? "Neues Match 🌸" : "Euer Chat ist offen 💬";
      const text = (other: string) =>
        isNew ? `Du und ${other} mögt euch.` : `Du kannst jetzt mit ${other} schreiben.`;
      const data = { type: "match", match_id: String(record.id) };
      return [
        { userId: userA, title, body: text(nameB), data },
        { userId: userB, title, body: text(nameA), data },
      ];
    }
  }

  return [];
}

async function displayName(userId: string): Promise<string> {
  const { data } = await supabase.from("profiles").select("display_name").eq("id", userId).single();
  return data?.display_name ?? "Jemand";
}

async function sendToUser(projectId: string, accessToken: string, n: Notification): Promise<number> {
  const { data: tokens } = await supabase.from("device_tokens").select("token").eq("user_id", n.userId);
  let sent = 0;
  for (const { token } of tokens ?? []) {
    const response = await fetch(`https://fcm.googleapis.com/v1/projects/${projectId}/messages:send`, {
      method: "POST",
      headers: { "Authorization": `Bearer ${accessToken}`, "Content-Type": "application/json" },
      body: JSON.stringify({
        message: {
          token,
          notification: { title: n.title, body: n.body },
          data: n.data,
          android: { priority: "high" },
        },
      }),
    });
    if (response.ok) {
      sent++;
    } else if (response.status === 404 || response.status === 400) {
      // Token ist abgelaufen oder ungültig → entfernen
      await supabase.from("device_tokens").delete().eq("token", token);
    }
  }
  return sent;
}

// OAuth-Token für FCM aus dem Service-Account (JWT, RS256) holen.
async function getAccessToken(sa: ServiceAccount): Promise<string> {
  const now = Math.floor(Date.now() / 1000);
  const encode = (value: unknown) => base64url(new TextEncoder().encode(JSON.stringify(value)));
  const unsigned = `${encode({ alg: "RS256", typ: "JWT" })}.${encode({
    iss: sa.client_email,
    scope: "https://www.googleapis.com/auth/firebase.messaging",
    aud: "https://oauth2.googleapis.com/token",
    iat: now,
    exp: now + 3600,
  })}`;

  const pem = sa.private_key.replace(/-----[^-]+-----/g, "").replace(/\s/g, "");
  const key = await crypto.subtle.importKey(
    "pkcs8",
    Uint8Array.from(atob(pem), (c) => c.charCodeAt(0)),
    { name: "RSASSA-PKCS1-v1_5", hash: "SHA-256" },
    false,
    ["sign"],
  );
  const signature = new Uint8Array(
    await crypto.subtle.sign("RSASSA-PKCS1-v1_5", key, new TextEncoder().encode(unsigned)),
  );

  const response = await fetch("https://oauth2.googleapis.com/token", {
    method: "POST",
    headers: { "Content-Type": "application/x-www-form-urlencoded" },
    body: new URLSearchParams({
      grant_type: "urn:ietf:params:oauth:grant-type:jwt-bearer",
      assertion: `${unsigned}.${base64url(signature)}`,
    }),
  });
  const json = await response.json();
  if (!response.ok) throw new Error(`FCM auth failed: ${JSON.stringify(json)}`);
  return json.access_token as string;
}

function base64url(bytes: Uint8Array): string {
  let binary = "";
  for (const byte of bytes) binary += String.fromCharCode(byte);
  return btoa(binary).replace(/\+/g, "-").replace(/\//g, "_").replace(/=+$/, "");
}
