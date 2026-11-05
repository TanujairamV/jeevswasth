<p align="center">
  <a href="http://nestjs.com/" target="blank"><img src="https://nestjs.com/img/logo-small.svg" width="120" alt="Nest Logo" /></a>
</p>

[circleci-image]: https://img.shields.io/circleci/build/github/nestjs/nest/master?token=abc123def456
[circleci-url]: https://circleci.com/gh/nestjs/nest

  <p align="center">A progressive <a href="http://nodejs.org" target="_blank">Node.js</a> framework for building efficient and scalable server-side applications.</p>
    <p align="center">
<a href="https://www.npmjs.com/~nestjscore" target="_blank"><img src="https://img.shields.io/npm/v/@nestjs/core.svg" alt="NPM Version" /></a>
<a href="https://www.npmjs.com/~nestjscore" target="_blank"><img src="https://img.shields.io/npm/l/@nestjs/core.svg" alt="Package License" /></a>
<a href="https://www.npmjs.com/~nestjscore" target="_blank"><img src="https://img.shields.io/npm/dm/@nestjs/common.svg" alt="NPM Downloads" /></a>
<a href="https://circleci.com/gh/nestjs/nest" target="_blank"><img src="https://img.shields.io/circleci/build/github/nestjs/nest/master" alt="CircleCI" /></a>
<a href="https://discord.gg/G7Qnnhy" target="_blank"><img src="https://img.shields.io/badge/discord-online-brightgreen.svg" alt="Discord"/></a>
<a href="https://opencollective.com/nest#backer" target="_blank"><img src="https://opencollective.com/nest/backers/badge.svg" alt="Backers on Open Collective" /></a>
<a href="https://opencollective.com/nest#sponsor" target="_blank"><img src="https://opencollective.com/nest/sponsors/badge.svg" alt="Sponsors on Open Collective" /></a>
  <a href="https://paypal.me/kamilmysliwiec" target="_blank"><img src="https://img.shields.io/badge/Donate-PayPal-ff3f59.svg" alt="Donate us"/></a>
    <a href="https://opencollective.com/nest#sponsor"  target="_blank"><img src="https://img.shields.io/badge/Support%20us-Open%20Collective-41B883.svg" alt="Support us"></a>
  <a href="https://twitter.com/nestframework" target="_blank"><img src="https://img.shields.io/twitter/follow/nestframework.svg?style=social&label=Follow" alt="Follow us on Twitter"></a>
</p>
  <!--[![Backers on Open Collective](https://opencollective.com/nest/backers/badge.svg)](https://opencollective.com/nest#backer)
  [![Sponsors on Open Collective](https://opencollective.com/nest/sponsors/badge.svg)](https://opencollective.com/nest#sponsor)-->

## Description

[Nest](https://github.com/nestjs/nest) framework TypeScript starter repository.

## Project setup

```bash
$ npm install
```

## Neon PostgreSQL and roles

Copy `.env.example` to `.env` and provide the database variable required by the command being run, plus the Firebase Admin service-account values. The NestJS server uses `DATABASE_URL`; migration commands use the explicitly selected `DATABASE_URL_PRODUCTION` or `DATABASE_URL_LOCAL`. The backend refuses to start when its database URL is missing, uses TLS for Neon, and never enables TypeORM schema synchronization.

### TypeORM migration workflow

The migration CLI runs in Node.js and uses `src/database/data-source.ts`.
Cloudflare Workers do not run TypeORM; they continue using the existing `pg`
connection supplied by the Hyperdrive binding.

Set the connection variables in the shell or in an untracked `.env` file. Do
not commit credentials:

```bash
export DATABASE_URL_PRODUCTION='<Neon production connection string>'
export DATABASE_URL_LOCAL='<local PostgreSQL connection string>'
export DATABASE_URL='<database used for migration generation>'
```

Production commands require `DATABASE_URL_PRODUCTION`. Local commands require
`DATABASE_URL_LOCAL`. The data source uses TLS, `synchronize: false`, and the
`typeorm_migrations` table for migration tracking.

Create an empty migration without connecting to a database:

```bash
npm run migration:create -- src/database/migrations/MigrationName
```

Generate a migration by comparing entities with the database selected by
`DATABASE_URL`:

```bash
npm run migration:generate -- src/database/migrations/MigrationName
```

Inspect or execute production migrations:

```bash
npm run migration:show
npm run migration:run
npm run migration:revert
```

Inspect or execute local migrations:

```bash
npm run migration:show:local
npm run migration:run:local
```

`migration:revert` reverts the latest migration and may remove or alter data;
review the migration and take a backup before running it. Migration generation
and execution are separate operations. No migration command is run
automatically by the Cloudflare Worker.

For a compiled production deployment, build first and run the TypeORM CLI
against the compiled data source:

```bash
npm run build
./node_modules/.bin/cross-env MIGRATION_TARGET=production node ./node_modules/typeorm/cli.js migration:show -d dist/database/data-source.js
./node_modules/.bin/cross-env MIGRATION_TARGET=production node ./node_modules/typeorm/cli.js migration:run -d dist/database/data-source.js
```

Firebase remains the identity provider. On the first authenticated request, the backend creates a `users` row; it loads roles from PostgreSQL on every guarded request and rejects disabled users. Veterinarian and surveillance-officer assignments are handled by the administrator review workflow. The administrator role is never selectable in Flutter.

Example SQL administration:

```sql
-- Available roles
SELECT id, name FROM roles ORDER BY name;

-- Bootstrap the first administrator from a trusted server/database session.
-- Replace FIREBASE_UID only after verifying the UID in Firebase Authentication.
-- This is intentionally not exposed through the application or registration UI.
INSERT INTO user_roles (user_id, role_id)
SELECT u.id, r.id FROM users u CROSS JOIN roles r
WHERE u.firebase_uid = 'FIREBASE_UID' AND r.name = 'administrator'
ON CONFLICT DO NOTHING;

-- Users and assigned roles
SELECT u.firebase_uid, u.email, u.display_name, u.is_active,
       COALESCE(string_agg(r.name, ', ' ORDER BY r.name), '') AS roles
FROM users u
LEFT JOIN user_roles ur ON ur.user_id = u.id
LEFT JOIN roles r ON r.id = ur.role_id
GROUP BY u.id
ORDER BY u.created_at;

-- Assign a role to a user (run only from a controlled admin session)
INSERT INTO user_roles (user_id, role_id)
SELECT u.id, r.id FROM users u CROSS JOIN roles r
WHERE u.firebase_uid = 'FIREBASE_UID' AND r.name = 'veterinarian'
ON CONFLICT DO NOTHING;

-- Remove a role assignment
DELETE FROM user_roles
WHERE user_id = (SELECT id FROM users WHERE firebase_uid = 'FIREBASE_UID')
  AND role_id = (SELECT id FROM roles WHERE name = 'veterinarian');

-- Disable an account
UPDATE users SET is_active = false, updated_at = now()
WHERE firebase_uid = 'FIREBASE_UID';
```

The existing report endpoint and response contract are unchanged. The Cloudflare Worker is the production path configured in Flutter and persists reports and administrator data to the Neon `reports` table. The NestJS path includes the same administrator API for Node deployments. Flutter remains local-first and keeps its existing retry-safe client report ID.

## Cloudflare Workers deployment

The NestJS entry point in `src/main.ts` starts a long-lived Express HTTP server with `NestFactory.create()` and `app.listen()`. That is not the Workers request model. The current TypeORM setup also depends on Node-oriented connection pooling and Nest application bootstrapping, while `firebase-admin` is not a clean Workers dependency because it relies on Node APIs and service-account credential handling. The original NestJS server remains available for Node hosting; Workers use the separate `src/worker.ts` adapter.

The Worker preserves Firebase ID-token verification using Firebase Secure Token JWKS, loads users and roles from PostgreSQL, provisions a default farmer role, rejects disabled accounts, and preserves the existing `POST /api/v1/reports` response contract. It uses the existing `pg` dependency with Cloudflare Hyperdrive. TypeORM is intentionally not bundled into this Worker path; it remains the Node migration and NestJS runtime dependency.

### Manual deployment steps

1. Install dependencies from `backend/` and create the Hyperdrive configuration using your Neon pooled connection string:

   ```bash
   npx wrangler login
   npx wrangler hyperdrive create jeevswasth-neon --connection-string="$DATABASE_URL"
   ```

2. Put the returned Hyperdrive ID in `backend/wrangler.jsonc` and replace `FIREBASE_PROJECT_ID` with the Firebase project ID.

   The checked-in Wrangler file intentionally contains placeholders. Deployment is blocked until both `REPLACE_WITH_HYPERDRIVE_ID` and `REPLACE_WITH_FIREBASE_PROJECT_ID` are replaced with real project configuration. The Worker uses the `HYPERDRIVE` binding's `connectionString`; it does not read `DATABASE_URL` at runtime.

3. Store Worker secrets. `DATABASE_URL` is not needed by the Worker after Hyperdrive is configured; do not put it in Wrangler vars or Flutter:

   ```bash
   npx wrangler secret put FIREBASE_PROJECT_ID
   npx wrangler secret put FIREBASE_CLIENT_EMAIL
   npx wrangler secret put FIREBASE_PRIVATE_KEY
   ```

   `FIREBASE_CLIENT_EMAIL` and `FIREBASE_PRIVATE_KEY` are retained in the secret list for compatibility with the Node NestJS deployment, but the Workers adapter verifies tokens through Firebase's public JWKS and does not require the private key.

4. Apply all TypeORM migrations against Neon using the Node backend migration workflow before publishing the Worker. The Worker expects `users`, `roles`, `user_roles`, `role_requests`, `reports`, and `admin_audit_logs` to exist. The administrator migration is `1710000004000-CreateAdminAuditAndReviewMetadata`.

5. Deploy:

   ```bash
   npm run worker:deploy
   ```

6. Use the Wrangler output URL as the Flutter API base URL, preserving the `/api/v1` prefix. No Firebase private key or database URL belongs in Flutter.

The first administrator must be provisioned only after the migration has run: authenticate once so the Firebase UID exists in `users`, verify the UID in the Firebase console, then run the bootstrap SQL above from a protected Neon SQL session. Never grant the role based on the first registration, email text, or a Flutter request. The SQL session should be restricted to trusted operators and recorded in the deployment change log.

The administrator API is available at `/api/v1/admin/overview`, `/applications`, `/users`, `/reports`, and `/audit-logs`, with review and account-status mutation endpoints protected by both Firebase token verification and the database-backed administrator role. Apply the migration before deploying either backend.

The role-selection flow uses `GET /api/v1/me` to resolve authoritative roles and `POST /api/v1/me/role-requests` to select a role. Farmer selection is assigned immediately after Firebase authentication; veterinarian and surveillance-officer selections create pending requests and never grant privileged access directly. Apply migration `1710000002000-CreateRoleRequests` before using these endpoints.

### Safe local checks before deployment

From `backend/`, after installing dependencies and providing local Wrangler values/secrets:

```bash
npm run build
npx wrangler types
npx wrangler deploy --dry-run
npm run worker:dev
```

Use a Firebase ID token only in local request testing; never commit it or put it in logs. Check the health response, an unauthenticated `POST /api/v1/reports` (expected 401), an invalid JSON request (expected 400 after authentication), an authenticated report insert, a retry with the same `clientReportId`, and `GET /api/v1/reports/mine`. These are instructions only; they have not been run here.

### First-deployment blockers

- Cloudflare authentication and the correct account/project must be selected.
- A real Hyperdrive ID must replace the placeholder.
- The Firebase project ID must replace its placeholder and match the Firebase tokens used by Flutter.
- The Worker must be allowed to reach the Neon database through Hyperdrive.
- The migrated `users`, `roles`, `user_roles`, and `reports` tables must exist in the Hyperdrive-targeted Neon database.
- Flutter must be configured with the deployed Worker URL, including `/api/v1`.

### Reports migration details

`1710000001000-CreateReports` creates a durable `reports` table with the existing report fields, optional location fields, ownership by Firebase UID, positive-count and coordinate checks, timestamps, and indexes for owner/time queries. `client_report_id` is unique per owner when supplied, allowing Flutter retries to return the original `reportId` with `idempotent: true` instead of inserting a duplicate.

## Compile and run the project

```bash
# development
$ npm run start

# watch mode
$ npm run start:dev

# production mode
$ npm run start:prod
```

## Run tests

```bash
# unit tests
$ npm run test

# e2e tests
$ npm run test:e2e

# test coverage
$ npm run test:cov
```

## Deployment

When you're ready to deploy your NestJS application to production, there are some key steps you can take to ensure it runs as efficiently as possible. Check out the [deployment documentation](https://docs.nestjs.com/deployment) for more information.

If you are looking for a cloud-based platform to deploy your NestJS application, check out [Mau](https://mau.nestjs.com), our official platform for deploying NestJS applications on AWS. Mau makes deployment straightforward and fast, requiring just a few simple steps:

```bash
$ npm install -g @nestjs/mau
$ mau deploy
```

With Mau, you can deploy your application in just a few clicks, allowing you to focus on building features rather than managing infrastructure.

## Observability

In production applications, observability is essential for understanding how your system behaves, detecting issues early, and maintaining reliable performance.

[NestJS Observe](https://observe.nestjs.com) automatically instruments your NestJS application, giving you deep visibility into your system with minimal setup:

- **Distributed tracing:** Follow requests across services and understand how they flow through your system.
- **Waterfall analysis:** Visualize request execution and identify slow operations, bottlenecks, and unexpected delays.
- **Performance analysis:** Analyze application performance in real time and quickly pinpoint areas that need optimization.
- **Metrics:** Track key application and infrastructure metrics to understand system health and performance trends.
- **Logging:** Centralize and correlate logs with traces and other telemetry to make debugging easier.
- **Error tracking:** Detect errors quickly and investigate their root causes with the surrounding context.
- **SLA monitoring:** Track service-level objectives and identify when your application is approaching or exceeding defined thresholds.
- **Alarms and alerts:** Set up alerts for critical errors, performance degradation, SLA violations, and other anomalies so your team can react quickly.

This project is already instrumented. Create a free account at [observe.nestjs.com](https://observe.nestjs.com), add an application, and paste the generated app key and secret into the `ObserveModule.forRoot()` call in `src/app.module.ts`.

The free plan needs no payment details and covers 300,000 events a month. You can also browse the [live demo](https://www.observe-demo.nestjs.com/dashboard) first - the whole dashboard over a busy service's data, with nothing to install.

## Resources

Check out a few resources that may come in handy when working with NestJS:

- Visit the [NestJS Documentation](https://docs.nestjs.com) to learn more about the framework.
- For questions and support, please visit our [Discord channel](https://discord.gg/G7Qnnhy).
- To dive deeper and get more hands-on experience, check out our official video [courses](https://courses.nestjs.com/).
- Deploy your application to AWS with the help of [NestJS Mau](https://mau.nestjs.com) in just a few clicks.
- Auto-instrument your application with [NestJS Observe](https://observe.nestjs.com). Distributed tracing, metrics, and logging made easy. Error tracking and performance monitoring for your NestJS applications.
- Visualize your application graph and interact with the NestJS application in real-time using [NestJS Devtools](https://devtools.nestjs.com).
- Need help with your project (part-time to full-time)? Check out our official [enterprise support](https://enterprise.nestjs.com).
- To stay in the loop and get updates, follow us on [X](https://x.com/nestframework) and [LinkedIn](https://linkedin.com/company/nestjs).
- Looking for a job, or have a job to offer? Check out our official [Jobs board](https://jobs.nestjs.com).

## Support

Nest is an MIT-licensed open source project. It can grow thanks to the sponsors and support by the amazing backers. If you'd like to join them, please [read more here](https://docs.nestjs.com/support).

## Stay in touch

- Author - [Kamil Myśliwiec](https://twitter.com/kammysliwiec)
- Website - [https://nestjs.com](https://nestjs.com/)
- Twitter - [@nestframework](https://twitter.com/nestframework)

## License

Nest is [MIT licensed](https://github.com/nestjs/nest/blob/master/LICENSE).
