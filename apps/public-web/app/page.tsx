import Link from 'next/link';
import React from 'react';

export default function Page(): React.ReactElement {
  return (
    <div>
      <h1>VibeBiz</h1>
      <Link href="/about">About</Link>
    </div>
  );
}
