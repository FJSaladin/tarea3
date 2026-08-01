
// Hotfix: formatear fecha en formato local dd/mm/aaaa
function formatearFecha(isoString) {
  const d = new Date(isoString);
  return d.toLocaleDateString('es-DO');
}
