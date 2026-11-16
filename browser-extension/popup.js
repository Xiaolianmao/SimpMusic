"use strict";

const endpoint = "http://127.0.0.1:48518/import";
const codeInput = document.querySelector("#code");
const status = document.querySelector("#status");
const youtubeButton = document.querySelector("#youtube");
const spotifyButton = document.querySelector("#spotify");

function showStatus(message, error = false) {
  status.textContent = message;
  status.classList.toggle("error", error);
}

function setBusy(busy) {
  youtubeButton.disabled = busy;
  spotifyButton.disabled = busy;
  codeInput.disabled = busy;
}

function allowedDomain(cookieDomain, domain) {
  const normalized = cookieDomain.replace(/^\./, "").toLowerCase();
  return normalized === domain || normalized.endsWith("." + domain);
}

async function importFromBrowser(target) {
  const code = codeInput.value.trim();
  if (!/^[A-Za-z0-9_-]{24}$/.test(code)) {
    showStatus("请输入软件中显示的完整一次性验证码。", true);
    return;
  }

  const domain = target === "YOUTUBE" ? "youtube.com" : "spotify.com";
  setBusy(true);
  showStatus("正在检查当前浏览器的登录状态…");
  try {
    // The cookies API accesses the current profile with browser-enforced permissions.
    // No browser database or OS encryption keys are read or modified.
    const cookies = await chrome.cookies.getAll({ domain });
    const records = cookies
      .filter((cookie) => allowedDomain(cookie.domain, domain))
      .map((cookie) => ({
        domain: cookie.domain,
        name: cookie.name,
        value: cookie.value,
        path: cookie.path || "/",
        expires: Number.isFinite(cookie.expirationDate)
          ? Math.max(0, Math.floor(cookie.expirationDate))
          : 0,
        secure: Boolean(cookie.secure),
        httpOnly: Boolean(cookie.httpOnly),
      }));

    const hasLogin = target === "SPOTIFY"
      ? records.some((item) => item.name === "sp_dc" && item.value.length > 0)
      : records.some((item) => ["SAPISID", "__Secure-3PAPISID", "__Secure-1PAPISID", "SID", "__Secure-3PSID"].includes(item.name) && item.value.length > 0);
    if (!hasLogin) {
      showStatus("当前浏览器配置尚未登录所选音乐服务，请先在浏览器中登录后再试。", true);
      return;
    }

    const response = await fetch(endpoint, {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        "X-SimpMusic-Code": code,
      },
      body: JSON.stringify({ target, cookies: records }),
      credentials: "omit",
      cache: "no-store",
      redirect: "error",
      // Chromium 145+ can require an explicit local-loopback permission.
      // Older Chromium versions simply ignore this fetch option.
      targetAddressSpace: "loopback",
    });
    if (!response.ok) {
      const errors = {
        403: "本机服务拒绝了请求，请使用修复版 SimpMusic 并重新生成验证码。",
        405: "本机服务当前不接受导入，请重新开始导入。",
        409: "本次导入已经完成，请重新开始一次。",
        413: "浏览器登录数据过多，无法导入。",
        400: "登录状态缺少必要信息或已过期，请重新登录后再试。",
        415: "请求格式不正确，请重新加载浏览器扩展。",
      };
      throw new Error(errors[response.status] || `导入未成功（本机状态：${response.status}），请重新开始导入。`);
    }
    codeInput.value = "";
    showStatus("已将登录状态传送到本机 SimpMusic，请返回应用确认结果。");
  } catch (error) {
    // Do not log the exception object, as it might accidentally carry URLs.
    // Do not expose exception objects, response bodies, cookies or one-time codes.
    // Error messages above are fixed application-controlled strings.
    const isKnownError = error instanceof Error &&
      /^(本机服务|本次导入|浏览器登录|登录状态|请求格式|导入未成功)/.test(error.message);
    showStatus(isKnownError
      ? error.message
      : "浏览器无法访问本机 127.0.0.1:48518。请确认软件正在等待导入，并允许浏览器的本地网络访问权限。", true);
  } finally {
    setBusy(false);
  }
}

youtubeButton.addEventListener("click", () => importFromBrowser("YOUTUBE"));
spotifyButton.addEventListener("click", () => importFromBrowser("SPOTIFY"));
