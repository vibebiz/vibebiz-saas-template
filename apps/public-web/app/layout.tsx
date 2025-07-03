import type { Metadata } from 'next';
import React from 'react';
import Navigation from '../src/components/Navigation';
import SkipLink from '../src/components/SkipLink';
import './globals.css';

export const metadata: Metadata = {
  title: 'VibeBiz Public Web',
  description: 'VibeBiz Public Web Application',
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
        <main id="main-content">{children}</main>
      </body>
    </html>
  );
}
