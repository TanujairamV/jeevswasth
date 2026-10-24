import { Test, TestingModule } from '@nestjs/testing';
import { INestApplication } from '@nestjs/common';
import request from 'supertest';
import { App } from 'supertest/types.js';
import { AppModule } from './../src/app.module.js';

describe('AppController (e2e)', () => {
  let app: INestApplication<App>;

  beforeEach(async () => {
    const moduleFixture: TestingModule = await Test.createTestingModule({
      imports: [AppModule],
    }).compile();

    app = moduleFixture.createNestApplication();
    await app.init();
  });

  it('/ (GET)', () => {
    return request(app.getHttpServer())
      .get('/')
      .expect(200)
      .expect('Hello World!');
  });

  it('accepts valid location data and exposes privacy-safe clusters', async () => {
    const timestamp = new Date().toISOString();
    for (let index = 0; index < 5; index += 1) {
      await request(app.getHttpServer())
        .post('/reports')
        .send({
          species: 'cattle',
          animalCount: index + 1,
          village: 'Bilaspur',
          symptoms: ['fever'],
          reportTimestamp: timestamp,
          location: { latitude: 29.685 + index * 0.001, longitude: 76.99 + index * 0.001, accuracyMeters: 12 },
        })
        .expect(201);
    }

    const response = await request(app.getHttpServer()).get('/reports/locations/clusters').expect(200);
    expect(response.body.privacy).toEqual({ minimumReports: 5, individualCoordinates: 'redacted' });
    expect(response.body.clusters).toHaveLength(1);
    expect(response.body.clusters[0]).toMatchObject({ reportCount: 5, affectedAnimals: 15, privacy: { minimumReports: 5, coordinatesAggregated: true } });
    expect(response.body.clusters[0]).not.toHaveProperty('locations');
  });

  it('rejects out-of-range coordinates', () => {
    return request(app.getHttpServer())
      .post('/reports')
      .send({ species: 'cattle', animalCount: 1, village: 'Bilaspur', symptoms: ['fever'], reportTimestamp: new Date().toISOString(), location: { latitude: 95, longitude: 76.99 } })
      .expect(400);
  });

  afterEach(async () => {
    await app.close();
  });
});
