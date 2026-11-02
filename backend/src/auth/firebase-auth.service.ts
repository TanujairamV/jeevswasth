import { Injectable, UnauthorizedException } from '@nestjs/common';
import { App, cert, getApps, initializeApp } from 'firebase-admin/app';
import { getAuth } from 'firebase-admin/auth';

@Injectable()
export class FirebaseAuthService {
  private app?: App;

  async verifyToken(token: string) {
    if (!token) throw new UnauthorizedException('Missing bearer token');
    try {
      if (!this.app) {
        this.app = getApps()[0] ?? initializeApp({
          credential: cert({
            projectId: process.env.FIREBASE_PROJECT_ID,
            clientEmail: process.env.FIREBASE_CLIENT_EMAIL,
            privateKey: process.env.FIREBASE_PRIVATE_KEY?.replace(/\\n/g, '\n'),
          }),
        });
      }
      return await getAuth(this.app).verifyIdToken(token);
    } catch {
      throw new UnauthorizedException('Invalid Firebase ID token');
    }
  }
}
