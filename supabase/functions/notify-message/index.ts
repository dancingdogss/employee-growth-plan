// supabase/functions/notify-message/index.ts
//
// Called from the owner dashboard to send a Telegram message to an employee.
// Inserts into owner_messages, sends the Telegram message with an inline button,
// then updates the row with the result.
//
// Required secret:
//   TELEGRAM_BOT_TOKEN <- from @BotFather
//
// SUPABASE_URL and SUPABASE_SERVICE_ROLE_KEY are auto-injected.

import { createClient } from "npm:@supabase/supabase-js@2";

const TELEGRAM_BOT_TOKEN = Deno.env.get("TELEGRAM_BOT_TOKEN")!;
const SUPABASE_URL = Deno.env.get("SUPABASE_URL")!;
const SUPABASE_SERVICE_ROLE_KEY = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;

const DASHBOARD_BASE_URL = "https://dancingdogss.github.io/wow-character/";

const supabase = createClient(SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY);

const CORS = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
};

function json(body: unknown, status = 200) {
  return new Response(JSON.stringify(body), {
    status,
    headers: { ...CORS, "Content-Type": "application/json" },
  });
}

function escapeHtml(value: unknown): string {
  return String(value ?? "")
    .replace(/&/g, "&amp;")
    .replace(/</g, "&lt;")
    .replace(/>/g, "&gt;")
    .replace(/"/g, "&quot;");
}

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response(null, { status: 204, headers: CORS });
  }

  if (req.method !== "POST") {
    return json({ ok: false, error: "Method not allowed" }, 405);
  }

  try {
    const { employee_id, title, message } = await req.json();

    const cleanEmployeeId = String(employee_id || "").trim();
    const cleanTitle = String(title || "").trim();
    const cleanMessage = String(message || "").trim();

    if (!cleanEmployeeId) {
      return json({ ok: false, error: "employee_id required" }, 400);
    }

    if (!cleanMessage) {
      return json({ ok: false, error: "message required" }, 400);
    }

    const { data: employee, error: empErr } = await supabase
      .from("employees")
      .select("id, name, employee_code, telegram_chat_id")
      .eq("id", cleanEmployeeId)
      .single();

    if (empErr || !employee) {
      return json({ ok: false, error: "Employee not found" }, 404);
    }

    if (!employee.telegram_chat_id) {
      return json({ ok: false, error: "Employee has no Telegram chat ID" }, 422);
    }

    const now = new Date().toISOString();

    const { data: msgRow, error: insertErr } = await supabase
      .from("owner_messages")
      .insert({
        employee_id: cleanEmployeeId,

        // Legacy compatibility:
        message: cleanMessage,
        sent_at: now,

        // New tracking columns:
        title: cleanTitle || null,
        body: cleanMessage,
        created_at: now,
        updated_at: now,
        telegram_chat_id: employee.telegram_chat_id,
      })
      .select("id")
      .single();

    if (insertErr || !msgRow) {
      console.error("owner_messages insert failed:", insertErr);
      return json(
        {
          ok: false,
          error: "Failed to save message: " + (insertErr?.message ?? "unknown"),
        },
        500
      );
    }

    const messageId = msgRow.id;

    const dashboardUrl =
      `${DASHBOARD_BASE_URL}` +
      `?emp=${encodeURIComponent(cleanEmployeeId)}` +
      `&msg=${encodeURIComponent(messageId)}` +
      `&source=telegram_message` +
      `&t=${Date.now()}` +
      `#sec-messages`;

    const lines: string[] = [];

    if (cleanTitle) {
      lines.push(`📩 <b>${escapeHtml(cleanTitle)}</b>`, "");
    } else {
      lines.push(`📩 <b>New message</b>`, "");
    }

    lines.push(
      escapeHtml(cleanMessage),
      "",
      `Employee: ${escapeHtml(employee.name)}${employee.employee_code ? ` (${escapeHtml(employee.employee_code)})` : ""}`,
      "",
      `Tap below to open your dashboard and confirm receipt.`
    );

    const text = lines.join("\n");

    const tgRes = await fetch(
      `https://api.telegram.org/bot${TELEGRAM_BOT_TOKEN}/sendMessage`,
      {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({
          chat_id: employee.telegram_chat_id,
          text,
          parse_mode: "HTML",
          disable_web_page_preview: true,
          reply_markup: {
            inline_keyboard: [
              [
                {
                  text: "Open Dashboard",
                  url: dashboardUrl,
                },
              ],
            ],
          },
        }),
      }
    );

    const tgText = await tgRes.text();

    let tgData: any = null;
    try {
      tgData = JSON.parse(tgText);
    } catch {
      tgData = null;
    }

    if (!tgRes.ok || tgData?.ok === false) {
      console.error("Telegram sendMessage failed:", tgText);

      await supabase
        .from("owner_messages")
        .update({
          telegram_error: tgText,
          updated_at: new Date().toISOString(),
        })
        .eq("id", messageId);

      return json({
        ok: false,
        message_id: messageId,
        error: "Telegram send failed",
        telegram_error: tgText,
      });
    }

    const telegramMessageId: number | null = tgData?.result?.message_id ?? null;

    await supabase
      .from("owner_messages")
      .update({
        telegram_message_id: telegramMessageId,
        telegram_sent_at: new Date().toISOString(),
        updated_at: new Date().toISOString(),
      })
      .eq("id", messageId);

    return json({
      ok: true,
      message_id: messageId,
      telegram_message_id: telegramMessageId,
    });
  } catch (err) {
    console.error("notify-message error:", err);
    return json({ ok: false, error: String(err) }, 500);
  }
});