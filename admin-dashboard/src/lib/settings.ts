import { prisma } from '@/lib/db';

export const RADIO_STREAM_URL_KEY = 'radio.streamUrl';

export async function getSetting(key: string) {
  const row = await prisma.appSetting.findUnique({ where: { key } });
  return row?.value ?? null;
}

export async function setSetting(key: string, value: string) {
  return await prisma.appSetting.upsert({
    where: { key },
    create: { key, value },
    update: { value },
  });
}

export async function getRadioStreamUrl() {
  const fromDb = await getSetting(RADIO_STREAM_URL_KEY);
  if (fromDb) return fromDb;

  const fallback = (process.env.DEFAULT_RADIO_STREAM_URL ?? '').trim();
  if (!fallback) return null;

  // Seed once for convenience in local dev.
  await setSetting(RADIO_STREAM_URL_KEY, fallback);
  return fallback;
}

export async function setRadioStreamUrl(url: string) {
  const normalized = url.trim();
  if (!normalized) throw new Error('Missing URL');
  if (!/^https?:\/\//i.test(normalized)) throw new Error('URL must start with http(s)://');
  await setSetting(RADIO_STREAM_URL_KEY, normalized);
  return normalized;
}
