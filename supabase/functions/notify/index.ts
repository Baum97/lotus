// Lotus – Push-Benachrichtigungen über Firebase Cloud Messaging (HTTP v1).
//
// Wird von den Datenbank-Triggern (private.notify_push, Format wie Supabase-Webhooks) aufgerufen:
//   * INSERT messages                 → "Neue Nachricht" an die andere Person
//   * INSERT matches                  → "Neues Match" an beide
//   * UPDATE matches queued → active  → "Euer Chat ist offen" an beide
//   * INSERT likes (kein Zurück-Like) → "Jemand mag dich" (höchstens alle 6 Stunden)
// Jede Person kann jede Art in der App abschalten (public.notification_settings).
//
// Secrets: FIREBASE_SERVICE_ACCOUNT (JSON), NOTIFY_WEBHOOK_SECRET.
// SUPABASE_URL und SUPABASE_SERVICE_ROLE_KEY stellt Supabase bereit.
// Nur für Tests: FCM_BASE_URL und GOOGLE_TOKEN_URL überschreiben die Google-Endpunkte.
//
// Datenschutz: Benachrichtigungen enthalten nie Nachrichtentexte, bei Likes nicht einmal den Namen.

import { createClient } from "npm:@supabase/supabase-js@2.45.4";
import { getGoogleAccessToken, type ServiceAccount } from "../_shared/google.ts";

type WebhookPayload = {
  type: "INSERT" | "UPDATE" | "DELETE";
  table: string;
  record: Record<string, unknown> | null;
  old_record: Record<string, unknown> | null;
};

type Kind = "messages" | "matches" | "likes";
type Notification = { userId: string; kind: Kind; title: string; body: string; data: Record<string, string> };

const FCM_BASE_URL = Deno.env.get("FCM_BASE_URL") ?? "https://fcm.googleapis.com";

const supabase = createClient(Deno.env.get("SUPABASE_URL")!, Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!);

Deno.serve(async (req) => {
  if (req.headers.get("x-webhook-secret") !== Deno.env.get("NOTIFY_WEBHOOK_SECRET")) {
    return new Response("unauthorized", { status: 401 });
  }

  const payload = (await req.json()) as WebhookPayload;
  const notifications = [];
  for (const n of await buildNotifications(payload)) {
    if (await wanted(n)) notifications.push(n);
  }
  if (notifications.length === 0) return Response.json({ sent: 0 });

  const serviceAccount = JSON.parse(Deno.env.get("FIREBASE_SERVICE_ACCOUNT")!) as ServiceAccount;
  const accessToken = await getGoogleAccessToken(serviceAccount, "https://www.googleapis.com/auth/firebase.messaging");
  let sent = 0;
  for (const n of notifications) {
    sent += await sendToUser(serviceAccount.project_id, accessToken, n);
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
      kind: "messages",
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
    if (!isNew && !unlocked) return [];
    const userA = record.user_a as string;
    const userB = record.user_b as string;
    const [nameA, nameB] = await Promise.all([displayName(userA), displayName(userB)]);
    const title = isNew ? "Neues Match 🌸" : "Euer Chat ist offen 💬";
    const text = (other: string) => isNew ? `Du und ${other} mögt euch.` : `Du kannst jetzt mit ${other} schreiben.`;
    const data = { type: "match", match_id: String(record.id) };
    return [
      { userId: userA, kind: "matches", title, body: text(nameB), data },
      { userId: userB, kind: "matches", title, body: text(nameA), data },
    ];
  }

  if (payload.table === "likes" && payload.type === "INSERT" && !record.is_like_back) {
    return [{
      userId: record.to_user as string,
      kind: "likes",
      title: "Jemand mag dich 🌸",
      body: "Schau nach, wer es ist – Zurück-Liken ist gratis.",
      data: { type: "like" },
    }];
  }

  return [];
}

/// Prüft die Einstellungen der Person; Likes höchstens alle 6 Stunden (atomar in der Datenbank).
async function wanted(n: Notification): Promise<boolean> {
  if (n.kind === "likes") {
    const { data } = await supabase.rpc("claim_like_push", { p_user: n.userId });
    return data === true;
  }
  const { data: settings } = await supabase
    .from("notification_settings")
    .select("messages, matches")
    .eq("user_id", n.userId)
    .maybeSingle();
  return !settings || settings[n.kind] !== false;
}

async function displayName(userId: string): Promise<string> {
  const { data } = await supabase.from("profiles").select("display_name").eq("id", userId).single();
  return data?.display_name ?? "Jemand";
}

async function sendToUser(projectId: string, accessToken: string, n: Notification): Promise<number> {
  const { data: tokens } = await supabase.from("device_tokens").select("token").eq("user_id", n.userId);
  let sent = 0;
  for (const { token } of tokens ?? []) {
    const response = await fetch(`${FCM_BASE_URL}/v1/projects/${projectId}/messages:send`, {
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
