export type FeaturedPlaylist = {
  id: string;
  title: string;
  description: string;
  imageSrc: string;
  /** Suggested query to try in /assistant/play */
  query: string;
};

export const FEATURED_PLAYLISTS: FeaturedPlaylist[] = [
  {
    id: 'bachata-love',
    title: 'Bachata Love',
    description: 'Romántica + clásica. Perfecta para noche.',
    imageSrc: '/playlists/bachata-love.svg',
    query: 'bachata amor',
  },
  {
    id: 'reggaeton-hits',
    title: 'Reggaetón Hits',
    description: 'Perreo limpio, energía alta.',
    imageSrc: '/playlists/reggaeton-hits.svg',
    query: 'reggaeton',
  },
  {
    id: 'salsa-classics',
    title: 'Salsa Classics',
    description: 'Salsa dura + clásicos para bailar.',
    imageSrc: '/playlists/salsa-classics.svg',
    query: 'salsa',
  },
  {
    id: 'merengue-party',
    title: 'Merengue Party',
    description: 'Sube el ánimo: merengue y fiesta.',
    imageSrc: '/playlists/merengue-party.svg',
    query: 'merengue',
  },
];
