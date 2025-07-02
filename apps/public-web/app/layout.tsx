import type { Metadata } from 'next';
import React from 'react';

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
        <main>{children}</main>
      </body>
    </html>
  );
}
