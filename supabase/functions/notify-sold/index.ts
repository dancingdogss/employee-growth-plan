// supabase/functions/notify-sold/index.ts
//
// Triggered by a Supabase Database Webhook on stock_units UPDATE.
// Sends a Telegram message to the employee when their stock unit's
// status just became 'sold_approved'.
//
// Required secrets (set these in Supabase Dashboard or via CLI):
//   TELEGRAM_BOT_TOKEN   <- from @BotFather
//
// SUPABASE_URL and SUPABASE_SERVICE_ROLE_KEY are auto-injected by
// Supabase into every Edge Function — you do NOT need to set those.

import { createClient } from "npm:@supabase/supabase-js@2";

const TELEGRAM_BOT_TOKEN = Deno.env.get("TELEGRAM_BOT_TOKEN")!;
const SUPABASE_URL = Deno.env.get("SUPABASE_URL")!;
const SUPABASE_SERVICE_ROLE_KEY = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;

const supabase = createClient(SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY);

Deno.serve(async (req) => {
  try {
    const payload = await req.json();

    // Database Webhooks send: { type, table, schema, record, old_record }
    if (payload.type !== "UPDATE") {
      return new Response("ignored: not an update", { status: 200 });
    }

    const newRow = payload.record;
    const oldRow = payload.old_record;

    // Only act the moment status transitions INTO sold_approved.
    // This ignores every other update (issue, edit, reset, employee_seen_at, etc.)
    if (newRow.status !== "sold_approved" || oldRow?.status === "sold_approved") {
      return new Response("ignored: not a new sold-approved transition", { status: 200 });
    }

    const { data: employee, error: empError } = await supabase
      .from("employees")
      .select("name, telegram_chat_id")
      .eq("id", newRow.employee_id)
      .single();

    if (empError || !employee?.telegram_chat_id) {
      console.log("No Telegram chat id for employee_id:", newRow.employee_id);
      return new Response("ignored: employee has no telegram_chat_id", { status: 200 });
    }

    const lines = [
      `✅ *${newRow.stock_id}* was just marked as sold`,
    ];
    if (newRow.order_id) lines.push(`Order: ${newRow.order_id}`);
    lines.push("", "Open the app and tap \"Mark as seen\" to confirm.");
    const text = lines.join("\n");

    const tgRes = await fetch(
      `https://api.telegram.org/bot${TELEGRAM_BOT_TOKEN}/sendMessage`,
      {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({
          chat_id: employee.telegram_chat_id,
          text,
          parse_mode: "Markdown",
        }),
      }
    );

    if (!tgRes.ok) {
      const errText = await tgRes.text();
      console.error("Telegram sendMessage failed:", errText);
      return new Response("telegram send failed (logged)", { status: 200 });
    }

    return new Response("notification sent", { status: 200 });
  } catch (err) {
    console.error("notify-sold error:", err);
    // Always return 200 — this is a best-effort notification, not a
    // critical-path operation. We never want it to retry indefinitely
    // or affect the database transaction that triggered it.
    return new Response("error (logged)", { status: 200 });
  }
});
