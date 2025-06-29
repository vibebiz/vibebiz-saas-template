import type { Metadata } from 'next';

export const metadata: Metadata = {
  title: 'VibeBiz Public Web',
  description: 'VibeBiz Public Web Application',
};

export default function RootLayout({ children }: { children: React.ReactNode }) {
  return (
    <html lang="en">
      <body>{children}</body>
    </html>
  );
}
