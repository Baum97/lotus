// Lotus – Käufe aus dem Google Play Store prüfen und freischalten.
//
// Die App ruft diese Function nach jedem Kauf mit dem Kauf-Token auf. Erst wenn Google den Kauf
// bestätigt, wird Lotus Plus freigeschaltet bzw. die Spende gezählt – die App kann nichts selbst eintragen.
//
// Secrets: GOOGLE_PLAY_SERVICE_ACCOUNT (JSON, mit Zugriff auf die Play Console),
//          ANDROID_PACKAGE_NAME (z. B. app.lotusdating.lotus).
// Nur für Tests: ANDROIDPUBLISHER_BASE_URL und GOOGLE_TOKEN_URL.

import { createClient } from "npm:@supabase/supabase-js@2.45.4";
import { getGoogleAccessToken, type ServiceAccount } from "../_shared/google.ts";

/** Produkte in der Play Console – IDs müssen dort genau so angelegt werden. */
export const PRODUCTS: Record<string, "plus" | "donation" | "success"> = {
  lotus_plus_monatlich: "plus",
  spende_klein: "donation",
  spende_mittel: "donation",
  spende_gross: "donation",
  beitrag_erfolg: "success",
};

const API = Deno.env.get("ANDROIDPUBLISHER_BASE_URL") ?? "https://androidpublisher.googleapis.com";

const admin = createClient(Deno.env.get("SUPABASE_URL")!, Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!);

Deno.serve(async (req) => {
  if (req.method !== "POST") return new Response("method not allowed", { status: 405 });

  // Angemeldete Person aus dem JWT der App
  const jwt = req.headers.get("Authorization")?.replace(/^Bearer /, "") ?? "";
  const { data: auth } = await admin.auth.getUser(jwt);
  const user = auth?.user;
  if (!user) return Response.json({ error: "not_authenticated" }, { status: 401 });

  const { productId, purchaseToken, amountMicros, currency } = await req.json();
  const kind = PRODUCTS[productId];
  if (!kind || typeof purchaseToken !== "string") {
    return Response.json({ error: "invalid_product" }, { status: 400 });
  }

  const pkg = Deno.env.get("ANDROID_PACKAGE_NAME")!;
  const sa = JSON.parse(Deno.env.get("GOOGLE_PLAY_SERVICE_ACCOUNT")!) as ServiceAccount;
  const token = await getGoogleAccessToken(sa, "https://www.googleapis.com/auth/androidpublisher");
  const headers = { Authorization: `Bearer ${token}` };
  const base = `${API}/androidpublisher/v3/applications/${pkg}/purchases`;

  let validUntil: string | null = null;
  let accountId: string | undefined;
  if (kind === "plus") {
    const res = await fetch(`${base}/subscriptionsv2/tokens/${encodeURIComponent(purchaseToken)}`, { headers });
    if (!res.ok) return Response.json({ error: "purchase_not_found" }, { status: 400 });
    const sub = await res.json();
    const active = ["SUBSCRIPTION_STATE_ACTIVE", "SUBSCRIPTION_STATE_IN_GRACE_PERIOD"].includes(sub.subscriptionState);
    const item = (sub.lineItems ?? []).find((i: { productId: string }) => i.productId === productId);
    if (!active || !item) return Response.json({ error: "purchase_not_active" }, { status: 400 });
    validUntil = item.expiryTime;
    accountId = sub.externalAccountIdentifiers?.obfuscatedExternalAccountId;
  } else {
    const res = await fetch(`${base}/products/${productId}/tokens/${encodeURIComponent(purchaseToken)}`, { headers });
    if (!res.ok) return Response.json({ error: "purchase_not_found" }, { status: 400 });
    const purchase = await res.json();
    if (purchase.purchaseState !== 0) return Response.json({ error: "purchase_not_completed" }, { status: 400 });
    accountId = purchase.obfuscatedExternalAccountId;
  }

  // Der Kauf muss mit diesem Konto gestartet worden sein (verhindert weitergegebene Kauf-Tokens)
  if (accountId !== user.id) return Response.json({ error: "purchase_account_mismatch" }, { status: 403 });

  const { error } = await admin.rpc("record_purchase", {
    p_user: user.id,
    p_product_id: productId,
    p_purchase_token: purchaseToken,
    p_kind: kind,
    p_valid_until: validUntil,
    p_amount_micros: typeof amountMicros === "number" ? amountMicros : null,
    p_currency: typeof currency === "string" ? currency : null,
  });
  if (error) return Response.json({ error: error.message }, { status: 500 });
  return Response.json({ ok: true, kind, validUntil });
});
