import React from 'react';
import { render, screen } from '@testing-library/react';
import Navigation from '../src/components/Navigation';

describe('Navigation Component', () => {
  beforeEach(() => {
    render(<Navigation />);
  });

  test('renders the main navigation landmark', () => {
    const navElement = screen.getByRole('navigation', { name: /main navigation/i });
    expect(navElement).toBeInTheDocument();
  });

  test('renders the VibeBiz brand link', () => {
    const brandLink = screen.getByRole('link', { name: /vibebiz/i });
    expect(brandLink).toBeInTheDocument();
    expect(brandLink).toHaveAttribute('href', '/');
  });

  const navLinks = [
    { name: /about/i, href: '/about' },
    { name: /features/i, href: '/features' },
    { name: /contact/i, href: '/contact' },
    { name: /sign in/i, href: '/login' },
    { name: /get started/i, href: '/signup' },
  ];

  navLinks.forEach(({ name, href }) => {
    test(`renders the ${name} link`, () => {
      const link = screen.getByRole('link', { name });
      expect(link).toBeInTheDocument();
      expect(link).toHaveAttribute('href', href);
    });
  });

  test('Get Started link has correct styling', () => {
    const getStartedLink = screen.getByRole('link', { name: /get started/i });
    expect(getStartedLink).toHaveClass('bg-blue-600');
  });
});
