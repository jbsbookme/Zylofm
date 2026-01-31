function isProbablyHttpUrl(value: string) {
  const v = value.trim();
  return /^https?:\/\//i.test(v);
}

function normalizeOrNull(value: string | undefined) {
  const v = (value ?? '').trim();
  if (!v) return null;
  if (!isProbablyHttpUrl(v)) return null;
  return v;
}

export const RADIO_24_7_URL = normalizeOrNull(process.env.NEXT_PUBLIC_RADIO_24_7_URL);
export const WHATSAPP_URL = normalizeOrNull(process.env.NEXT_PUBLIC_WHATSAPP_URL);
export const INSTAGRAM_URL = normalizeOrNull(process.env.NEXT_PUBLIC_INSTAGRAM_URL);
export const TIKTOK_URL = normalizeOrNull(process.env.NEXT_PUBLIC_TIKTOK_URL);
export const YOUTUBE_URL = normalizeOrNull(process.env.NEXT_PUBLIC_YOUTUBE_URL);
export const FACEBOOK_URL = normalizeOrNull(process.env.NEXT_PUBLIC_FACEBOOK_URL);

export type ExternalLink = {
  id: string;
  label: string;
  href: string;
};

export const EXTERNAL_LINKS: ExternalLink[] = [
  ...(RADIO_24_7_URL ? [{ id: 'radio', label: 'Radio ZyloFM 24/7', href: RADIO_24_7_URL }] : []),
  ...(WHATSAPP_URL ? [{ id: 'whatsapp', label: 'WhatsApp', href: WHATSAPP_URL }] : []),
  ...(INSTAGRAM_URL ? [{ id: 'instagram', label: 'Instagram', href: INSTAGRAM_URL }] : []),
  ...(TIKTOK_URL ? [{ id: 'tiktok', label: 'TikTok', href: TIKTOK_URL }] : []),
  ...(YOUTUBE_URL ? [{ id: 'youtube', label: 'YouTube', href: YOUTUBE_URL }] : []),
  ...(FACEBOOK_URL ? [{ id: 'facebook', label: 'Facebook', href: FACEBOOK_URL }] : []),
];
