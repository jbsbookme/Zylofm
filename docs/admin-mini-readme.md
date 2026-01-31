# Admin Dashboard — Mini README (ZyloFM)

## Acceso
- URL: `https://admin.jblatinmusic.net`
- Login: usa las credenciales admin creadas en el backend.

## 6) Cómo usar el Admin

### A) Subir música (Upload Track)
1. Entra a **Upload Track**.
2. Selecciona el archivo de audio.
3. Completa **Título / Artista / Keywords** (importante para búsquedas).
4. Sube el track y espera confirmación.

**Tips**
- Usa keywords reales: género, mood, artista, “radio”, “en vivo”, etc.
- Si el track no aparece, revisa que esté **Active** en la biblioteca.

### B) Aprobar DJs (Pending DJs)
1. Entra a **Pending DJs**.
2. Revisa cada solicitud (nombre, link, info).
3. Presiona **Approve** o **Reject**.

**Criterios sugeridos**
- Datos completos y consistentes.
- Enlaces válidos.
- Contenido alineado a la marca.

### C) Biblioteca (Music Library)
- **Activate / Deactivate:** controla visibilidad sin borrar.
- **Edit keywords:** mejora resultados del assistant.
- **Delete:** elimina definitivamente (usar con cuidado).

### D) Test Player (Assistant)
- Usa **Test Player** para probar `POST /assistant/play` desde UI.
- Confirma que el track correcto se reproduce y que el “Now Playing” muestra el título.

## Troubleshooting rápido
- **Login falla:** revisa que la API esté arriba y que `CORS_ORIGINS` incluya el dominio del admin.
- **500 en la API:** suele ser `DATABASE_URL` faltante o inválida.
- **No carga contenido:** revisa `NEXT_PUBLIC_API_URL` en el admin.
