import {
  createRemoteJWKSet,
  jwtVerify,
  type JWTPayload,
} from 'jose';
import {
  JOSEError,
  JWTClaimValidationFailed,
  JWTExpired,
  JWTInvalid,
  JWSSignatureVerificationFailed,
} from 'jose/errors';
import { Client } from 'pg';

export interface WorkerEnv {
  HYPERDRIVE: { connectionString: string };
  FIREBASE_PROJECT_ID: string;
  FIREBASE_CLIENT_EMAIL?: string;
  FIREBASE_PRIVATE_KEY?: string;
}

interface Identity extends JWTPayload {
  user_id?: string;
  email?: string;
  name?: string;
}

interface Report {
  species: string;
  animalCount: number;
  village: string;
  symptoms: string[];
  reportTimestamp: string;
  clientReportId?: string;
  farmerName?: string;
  farmerPhone?: string;
  clinicalSigns?: string[];
  notes?: string;
  location?: { latitude: number; longitude: number; address?: string; accuracyMeters?: number };
  ownerUid?: string;
}

function json(body: unknown, status = 200) {
  return Response.json(body, { status, headers: corsHeaders() });
}

function corsHeaders() {
  return {
    'Access-Control-Allow-Origin': '*',
    'Access-Control-Allow-Headers': 'Authorization, Content-Type',
    'Access-Control-Allow-Methods': 'GET, POST, OPTIONS',
  };
}

async function withDatabase<T>(env: WorkerEnv, fn: (client: Client) => Promise<T>) {
  if (!env.HYPERDRIVE?.connectionString) throw new Error('HYPERDRIVE binding is required');
  const client = new Client({ connectionString: env.HYPERDRIVE.connectionString });
  await client.connect();
  try { return await fn(client); } finally { await client.end(); }
}

async function authenticate(request: Request, env: WorkerEnv) {
  const value = request.headers.get('Authorization');
  if (!value?.startsWith('Bearer ')) throw new Response('Missing bearer token', { status: 401, headers: corsHeaders() });
  const token = value.slice(7);
  let verified;
  try {
    const keys = createRemoteJWKSet(new URL('https://www.googleapis.com/service_accounts/v1/jwk/securetoken@system.gserviceaccount.com'));
    verified = await jwtVerify<Identity>(token, keys, {
      issuer: `https://securetoken.google.com/${env.FIREBASE_PROJECT_ID}`,
      audience: env.FIREBASE_PROJECT_ID,
    });
  } catch (error) {
    // Log only the JOSE error category. Never log the token or Authorization header.
    if (error instanceof JWTExpired) {
      console.warn('Firebase token rejected: expired');
      throw new Response('Firebase session expired. Sign in again.', { status: 401, headers: corsHeaders() });
    }
    if (error instanceof JWSSignatureVerificationFailed) {
      console.warn('Firebase token rejected: invalid signature');
      throw new Response('Invalid Firebase ID token.', { status: 401, headers: corsHeaders() });
    }
    if (error instanceof JWTClaimValidationFailed) {
      const claim = error.claim;
      const reason = claim === 'iss' ? 'invalid issuer' : claim === 'aud' ? 'invalid audience' : `invalid ${claim} claim`;
      console.warn(`Firebase token rejected: ${reason}`);
      throw new Response('Invalid Firebase ID token.', { status: 401, headers: corsHeaders() });
    }
    if (error instanceof JOSEError && error.code.startsWith('ERR_JWKS')) {
      console.error('Firebase JWKS retrieval failed:', error instanceof Error ? error.name : 'unknown_error');
      throw new Response('Authentication service temporarily unavailable.', { status: 503, headers: corsHeaders() });
    }
    if (error instanceof JWTInvalid) {
      console.warn('Firebase token rejected: malformed token');
      throw new Response('Invalid Firebase ID token.', { status: 401, headers: corsHeaders() });
    }
    if (error instanceof TypeError || (error instanceof Error && /fetch|network|timeout/i.test(error.message))) {
      console.error('Firebase JWKS retrieval failed:', error instanceof Error ? error.name : 'unknown_error');
      throw new Response('Authentication service temporarily unavailable.', { status: 503, headers: corsHeaders() });
    }
    console.warn('Firebase token rejected: malformed token', error instanceof Error ? error.name : 'unknown_error');
    throw new Response('Invalid Firebase ID token.', { status: 401, headers: corsHeaders() });
  }
  const uid = verified.payload.sub;
  if (!uid) throw new Response('Invalid Firebase ID token: missing Firebase UID', { status: 401, headers: corsHeaders() });
  try {
    const user = await withDatabase(env, async (client) => {
      const result = await client.query(`
        INSERT INTO users (firebase_uid, email, display_name)
        VALUES ($1, $2, $3)
        ON CONFLICT (firebase_uid) DO UPDATE SET email = EXCLUDED.email, display_name = EXCLUDED.display_name, updated_at = now()
        RETURNING id, firebase_uid, email, display_name, is_active`,
        [uid, verified.payload.email ?? `${uid}@unknown.invalid`, verified.payload.name ?? null]);
      const current = result.rows[0];
      if (!current.is_active) throw new Response('Account is disabled', { status: 403 });
      const roles = await client.query(`SELECT r.name FROM roles r JOIN user_roles ur ON ur.role_id = r.id WHERE ur.user_id = $1`, [current.id]);
      console.log('Authenticated profile loaded:', { roleCount: roles.rows.length, roles: roles.rows.map((row) => row.name) });
      return { ...current, roles: roles.rows.map((row) => row.name) };
    });
    return { uid, user };
  } catch (error) {
    if (error instanceof Response) throw error;
    console.error('Authenticated user lookup failed', error instanceof Error ? error.name : 'unknown_error');
    throw new Response('Authenticated user lookup failed. Check the Worker database configuration and migrations.', { status: 500, headers: corsHeaders() });
  }
}

function validLocation(location: unknown) {
  if (!location || typeof location !== 'object') return false;
  const candidate = location as Record<string, unknown>;
  return typeof candidate.latitude === 'number' && Number.isFinite(candidate.latitude) && candidate.latitude >= -90 && candidate.latitude <= 90
    && typeof candidate.longitude === 'number' && Number.isFinite(candidate.longitude) && candidate.longitude >= -180 && candidate.longitude <= 180;
}

export default {
  async fetch(request: Request, env: WorkerEnv): Promise<Response> {
    if (request.method === 'OPTIONS') return new Response(null, { status: 204, headers: corsHeaders() });
    const url = new URL(request.url);
    if (url.pathname === '/api/v1/' || url.pathname === '/api/v1') return json('Hello World!');
    try {
      if (url.pathname === '/api/v1/reports' && request.method === 'POST') {
        const auth = await authenticate(request, env);
        let report: Partial<Report>;
        try {
          report = await request.json() as Partial<Report>;
        } catch {
          return json({ status: 'rejected', message: 'Request body must be valid JSON' }, 400);
        }
        const missing = [
          ['species', typeof report.species === 'string' && report.species.trim().length > 0],
          ['animalCount', typeof report.animalCount === 'number' && Number.isInteger(report.animalCount) && report.animalCount > 0],
          ['village', typeof report.village === 'string' && report.village.trim().length > 0],
          ['symptoms', Array.isArray(report.symptoms) && report.symptoms.length > 0],
          ['reportTimestamp', typeof report.reportTimestamp === 'string' && !Number.isNaN(Date.parse(report.reportTimestamp))],
          ['location', report.location === undefined || validLocation(report.location)],
        ].filter(([, valid]) => !valid).map(([field]) => field);
        if (missing.length) return json({ status: 'rejected', message: 'Invalid livestock health report', missing }, 400);
        const complete = { ...report, ownerUid: auth.uid } as Report;
        const persisted = await withDatabase(env, async (client) => {
          const result = await client.query(`
            INSERT INTO reports (
              report_id, owner_firebase_uid, client_report_id, species, animal_count,
              village, symptoms, report_timestamp, farmer_name, farmer_phone,
              clinical_signs, notes, latitude, longitude, location_address, accuracy_meters
            ) VALUES ($1, $2, $3, $4, $5, $6, $7::jsonb, $8, $9, $10, $11::jsonb, $12, $13, $14, $15, $16)
            ON CONFLICT (owner_firebase_uid, client_report_id) DO NOTHING
            RETURNING report_id`,
            [
              `report_${crypto.randomUUID()}`, auth.uid, complete.clientReportId ?? null,
              complete.species, complete.animalCount, complete.village, JSON.stringify(complete.symptoms),
              complete.reportTimestamp, complete.farmerName ?? null, complete.farmerPhone ?? null,
              JSON.stringify(complete.clinicalSigns ?? []), complete.notes ?? null,
              complete.location?.latitude ?? null, complete.location?.longitude ?? null,
              complete.location?.address ?? null, complete.location?.accuracyMeters ?? null,
            ],
          );
          if (result.rowCount) return { reportId: result.rows[0].report_id, idempotent: false };
          const existing = await client.query(`SELECT report_id FROM reports WHERE owner_firebase_uid = $1 AND client_report_id = $2`, [auth.uid, complete.clientReportId]);
          return { reportId: existing.rows[0].report_id, idempotent: true };
        });
        return json({ reportId: persisted.reportId, status: 'submitted', ...(persisted.idempotent ? { idempotent: true } : {}) }, persisted.idempotent ? 200 : 201);
      }
      if (url.pathname === '/api/v1/me' && request.method === 'GET') {
        const auth = await authenticate(request, env);
        const pending = await withDatabase(env, (client) => client.query(`SELECT r.name AS role, rr.status FROM role_requests rr JOIN roles r ON r.id = rr.role_id WHERE rr.user_id = $1 AND rr.status = 'pending' ORDER BY rr.created_at DESC`, [auth.user.id]));
        return json({ status: 'ok', user: { firebaseUid: auth.uid, email: auth.user.email, displayName: auth.user.display_name, roles: auth.user.roles, pendingRoleRequests: pending.rows.map((row) => row.role) } });
      }
      if (url.pathname === '/api/v1/me/role-requests' && request.method === 'POST') {
        const auth = await authenticate(request, env);
        const body = await request.json() as { role?: unknown };
        if (!['farmer', 'veterinarian', 'surveillance_officer'].includes(body.role as string)) return json({ status: 'rejected', message: 'Invalid role selection.' }, 400);
        const role = body.role as string;
        const result = await withDatabase(env, async (client) => {
          const existing = await client.query(`SELECT 1 FROM user_roles ur JOIN roles r ON r.id = ur.role_id WHERE ur.user_id = $1 AND r.name = $2`, [auth.user.id, role]);
          if (existing.rowCount) return 'assigned';
          if (role === 'farmer') {
            await client.query(`INSERT INTO user_roles (user_id, role_id) SELECT $1, id FROM roles WHERE name = $2 ON CONFLICT DO NOTHING`, [auth.user.id, role]);
            return 'assigned';
          }
          await client.query(`INSERT INTO role_requests (user_id, role_id) SELECT $1, id FROM roles WHERE name = $2 ON CONFLICT (user_id, role_id, status) DO NOTHING`, [auth.user.id, role]);
          return 'pending';
        });
        return json({ status: 'ok', role, assignment: result });
      }
      if (url.pathname === '/api/v1/reports/mine' && request.method === 'GET') {
        const auth = await authenticate(request, env);
        const result = await withDatabase(env, (client) => client.query(`
          SELECT report_id, species, animal_count, village, symptoms, report_timestamp,
                 client_report_id, farmer_name, farmer_phone, clinical_signs, notes,
                 latitude, longitude, location_address, accuracy_meters
          FROM reports WHERE owner_firebase_uid = $1 ORDER BY created_at DESC`, [auth.uid]));
        return json({ status: 'ok', reports: result.rows.map((row) => ({
          reportId: row.report_id,
          species: row.species,
          animalCount: row.animal_count,
          village: row.village,
          symptoms: row.symptoms,
          reportTimestamp: new Date(row.report_timestamp).toISOString(),
          clientReportId: row.client_report_id ?? undefined,
          farmerName: row.farmer_name ?? undefined,
          farmerPhone: row.farmer_phone ?? undefined,
          clinicalSigns: row.clinical_signs,
          notes: row.notes ?? undefined,
          ...(row.latitude === null ? {} : { location: { latitude: row.latitude, longitude: row.longitude, ...(row.location_address === null ? {} : { address: row.location_address }), ...(row.accuracy_meters === null ? {} : { accuracyMeters: row.accuracy_meters }) } }),
          ownerUid: auth.uid,
        })) });
      }
      return json({ status: 'not_found' }, 404);
    } catch (error) {
      if (error instanceof Response) return error;
      console.error('Worker request failed', error);
      return json({ status: 'error', message: 'Internal server error' }, 500);
    }
  },
};
