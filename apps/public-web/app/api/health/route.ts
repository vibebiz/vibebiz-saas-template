import { NextResponse } from 'next/server';

/**
 * Health check endpoint for E2E tests and monitoring
 * Returns 200 OK when the application is ready to serve requests
 */
export async function GET(): Promise<NextResponse> {
  try {
    // Basic health check - application is running
    return NextResponse.json(
      {
        status: 'healthy',
        timestamp: new Date().toISOString(),
        service: 'public-web',
        version: process.env.npm_package_version || '1.0.0',
      },
      { status: 200 }
    );
  } catch (error) {
    // If health check fails, return 503 Service Unavailable
    return NextResponse.json(
      {
        status: 'unhealthy',
        timestamp: new Date().toISOString(),
        service: 'public-web',
        error: error instanceof Error ? error.message : 'Unknown error',
      },
      { status: 503 }
    );
  }
}
