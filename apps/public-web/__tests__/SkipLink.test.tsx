import React from 'react';
import { render, screen } from '@testing-library/react';
import SkipLink from '../src/components/SkipLink';

describe('SkipLink Component', () => {
  beforeEach(() => {
    render(<SkipLink />);
  });

  test('renders a link with the correct href', () => {
    const link = screen.getByRole('link', { name: /skip to main content/i });
    expect(link).toBeInTheDocument();
    expect(link).toHaveAttribute('href', '#main-content');
  });

  test('has the correct accessibility class', () => {
    const link = screen.getByRole('link', { name: /skip to main content/i });
    expect(link).toHaveClass('sr-only');
  });
});
