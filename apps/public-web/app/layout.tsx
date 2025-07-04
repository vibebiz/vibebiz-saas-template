import type { Metadata } from 'next';
import React from 'react';
import Navigation from '../src/components/Navigation';
import SkipLink from '../src/components/SkipLink';
import './globals.css';

export const metadata: Metadata = {
  title: 'VibeBiz - SaaS Platform for Growing Businesses',
  description:
    'The ultimate SaaS platform for growing businesses. Streamline your operations, boost productivity, and scale with confidence.',
};

export default function RootLayout({
  children,
}: {
  children: React.ReactNode;
}): React.ReactElement {
  return (
    <html lang="en">
      <body>
        <SkipLink />
        <Navigation />
        <main id="main-content" role="main">
          {children}
        </main>
      </body>
    </html>
  );
}
