'use strict';

// Provider lưu tệp: gửi ảnh lên Supabase Storage qua REST API bằng fetch có sẵn của Node.
// Khóa service role (SUPABASE_SERVICE_KEY) chỉ nằm ở backend, không bao giờ đưa vào app.
function createStorage({ config }) {
  const { supabaseUrl, supabaseServiceKey, supabaseBucket } = config;
  const daCauHinh = Boolean(supabaseUrl && supabaseServiceKey && supabaseBucket);

  // Khóa kiểu mới (sb_secret_...) chỉ gửi ở header apikey; khóa JWT cũ gửi cả Authorization.
  function headers(contentType) {
    const h = { apikey: supabaseServiceKey, 'content-type': contentType, 'x-upsert': 'false' };
    if (!String(supabaseServiceKey).startsWith('sb_')) h.authorization = `Bearer ${supabaseServiceKey}`;
    return h;
  }

  return {
    daCauHinh,
    // Trả đường dẫn công khai của tệp (bucket phải để public để app hiển thị ảnh).
    async taiLen(duongDan, buffer, contentType) {
      const base = supabaseUrl.replace(/\/+$/, '');
      const res = await fetch(`${base}/storage/v1/object/${supabaseBucket}/${duongDan}`, {
        method: 'POST', headers: headers(contentType), body: buffer, signal: AbortSignal.timeout(30000),
      });
      if (!res.ok) {
        const text = await res.text().catch(() => '');
        throw new Error(`Supabase Storage trả ${res.status}: ${text.slice(0, 200)}`);
      }
      return `${base}/storage/v1/object/public/${supabaseBucket}/${duongDan}`;
    },
  };
}

module.exports = { createStorage };
