export async function GET() {
  return Response.json({ ok: true, service: "jelad-web", timestamp: new Date().toISOString() });
}