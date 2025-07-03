import Link from 'next/link';
import React from 'react';

export default function Page(): React.ReactElement {
  return (
    <div className="min-h-screen bg-gray-50">
      {/* Hero Section */}
      <section className="bg-white py-20">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
          <div className="text-center">
            <h1 className="text-4xl font-bold text-gray-900 sm:text-5xl md:text-6xl">
              Welcome to VibeBiz
            </h1>
            <p className="mt-6 text-xl text-gray-600 max-w-3xl mx-auto">
              The ultimate SaaS platform for growing businesses. Streamline your
              operations, boost productivity, and scale with confidence.
            </p>
            <div className="mt-8 flex justify-center space-x-4">
              <Link
                href="/signup"
                className="bg-blue-600 text-white px-8 py-3 rounded-md text-lg font-medium hover:bg-blue-700 focus:outline-none focus:ring-2 focus:ring-blue-500 focus:ring-offset-2 transition-colors"
              >
                Get Started Free
              </Link>
              <Link
                href="/demo"
                className="bg-white text-blue-600 border-2 border-blue-600 px-8 py-3 rounded-md text-lg font-medium hover:bg-blue-50 focus:outline-none focus:ring-2 focus:ring-blue-500 focus:ring-offset-2 transition-colors"
              >
                View Demo
              </Link>
            </div>
          </div>
        </div>
      </section>

      {/* Features Section */}
      <section className="py-16 bg-gray-50">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
          <div className="text-center">
            <h2 className="text-3xl font-bold text-gray-900">Why Choose VibeBiz?</h2>
            <p className="mt-4 text-xl text-gray-600">
              Powerful features designed for modern businesses
            </p>
          </div>
          <div className="mt-12 grid grid-cols-1 md:grid-cols-3 gap-8">
            <div className="bg-white p-6 rounded-lg shadow-sm">
              <h3 className="text-xl font-semibold text-gray-900 mb-4">Easy Setup</h3>
              <p className="text-gray-600 mb-4">
                Get started in minutes with our intuitive onboarding process.
              </p>
              <Link
                href="/learn-more"
                className="inline-flex items-center justify-center w-full px-4 py-2 border border-gray-300 text-gray-700 bg-white hover:bg-gray-50 focus:outline-none focus:ring-2 focus:ring-blue-500 focus:ring-offset-2 rounded-md transition-colors"
              >
                Learn More
              </Link>
            </div>
            <div className="bg-white p-6 rounded-lg shadow-sm">
              <h3 className="text-xl font-semibold text-gray-900 mb-4">
                Scalable Platform
              </h3>
              <p className="text-gray-600 mb-4">
                Grow from startup to enterprise with our flexible architecture.
              </p>
              <Link
                href="/scaling"
                className="inline-flex items-center justify-center w-full px-4 py-2 border border-gray-300 text-gray-700 bg-white hover:bg-gray-50 focus:outline-none focus:ring-2 focus:ring-blue-500 focus:ring-offset-2 rounded-md transition-colors"
              >
                Explore Scaling
              </Link>
            </div>
            <div className="bg-white p-6 rounded-lg shadow-sm">
              <h3 className="text-xl font-semibold text-gray-900 mb-4">24/7 Support</h3>
              <p className="text-gray-600 mb-4">
                Our expert team is always here to help you succeed.
              </p>
              <Link
                href="/support"
                className="inline-flex items-center justify-center w-full px-4 py-2 border border-gray-300 text-gray-700 bg-white hover:bg-gray-50 focus:outline-none focus:ring-2 focus:ring-blue-500 focus:ring-offset-2 rounded-md transition-colors"
              >
                Contact Support
              </Link>
            </div>
          </div>
        </div>
      </section>

      {/* CTA Section */}
      <section className="bg-blue-600 py-16">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 text-center">
          <h2 className="text-3xl font-bold text-white mb-4">
            Ready to Transform Your Business?
          </h2>
          <p className="text-xl text-blue-100 mb-8">
            Join thousands of companies already using VibeBiz to accelerate their
            growth.
          </p>
          <div className="flex justify-center space-x-4">
            <Link
              href="/signup"
              className="bg-white text-blue-600 px-8 py-3 rounded-md text-lg font-medium hover:bg-gray-100 focus:outline-none focus:ring-2 focus:ring-white focus:ring-offset-2 focus:ring-offset-blue-600 transition-colors"
            >
              Start Free Trial
            </Link>
            <Link
              href="/contact"
              className="bg-blue-700 text-white px-8 py-3 rounded-md text-lg font-medium hover:bg-blue-800 focus:outline-none focus:ring-2 focus:ring-white focus:ring-offset-2 focus:ring-offset-blue-600 transition-colors"
            >
              Contact Sales
            </Link>
          </div>
        </div>
      </section>
    </div>
  );
}
