import Link from 'next/link';
import React from 'react';

export default function Navigation(): React.ReactElement {
  return (
    <nav
      className="bg-white border-b border-gray-200 px-4 py-3"
      role="navigation"
      aria-label="Main navigation"
    >
      <div className="max-w-7xl mx-auto flex items-center justify-between">
        <div className="flex items-center space-x-8">
          <Link
            href="/"
            className="text-xl font-bold text-gray-900 focus:outline-none focus:ring-2 focus:ring-blue-500 focus:ring-offset-2 rounded-sm"
          >
            VibeBiz
          </Link>
          <div className="flex space-x-6">
            <Link
              href="/about"
              className="text-gray-700 hover:text-gray-900 focus:outline-none focus:ring-2 focus:ring-blue-500 focus:ring-offset-2 rounded-sm px-2 py-1"
            >
              About
            </Link>
            <Link
              href="/features"
              className="text-gray-700 hover:text-gray-900 focus:outline-none focus:ring-2 focus:ring-blue-500 focus:ring-offset-2 rounded-sm px-2 py-1"
            >
              Features
            </Link>
            <Link
              href="/contact"
              className="text-gray-700 hover:text-gray-900 focus:outline-none focus:ring-2 focus:ring-blue-500 focus:ring-offset-2 rounded-sm px-2 py-1"
            >
              Contact
            </Link>
          </div>
        </div>
        <div className="flex items-center space-x-4">
          <Link
            href="/login"
            className="text-gray-700 hover:text-gray-900 focus:outline-none focus:ring-2 focus:ring-blue-500 focus:ring-offset-2 rounded-sm px-3 py-1"
          >
            Sign In
          </Link>
          <Link
            href="/signup"
            className="bg-blue-600 text-white px-4 py-2 rounded-md hover:bg-blue-700 focus:outline-none focus:ring-2 focus:ring-blue-500 focus:ring-offset-2 transition-colors"
          >
            Get Started
          </Link>
        </div>
      </div>
    </nav>
  );
}
