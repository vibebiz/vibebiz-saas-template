/**
 * Unit tests for Button component
 */

import React from 'react';
import { render, screen, fireEvent } from '@testing-library/react';
import userEvent from '@testing-library/user-event';
import { Button, ButtonProps } from '../src/components/Button';

describe('Button Component', () => {
  const defaultProps: ButtonProps = {
    children: 'Click me',
  };

  const renderButton = (props: Partial<ButtonProps> = {}) => {
    return render(<Button {...defaultProps} {...props} />);
  };

  describe('Rendering', () => {
    test('renders with default props', () => {
      renderButton();

      const button = screen.getByRole('button', { name: /click me/i });
      expect(button).toBeInTheDocument();
      expect(button).toHaveAttribute('type', 'button');
    });

    test('renders with custom children', () => {
      renderButton({ children: 'Custom Text' });

      expect(screen.getByRole('button', { name: /custom text/i })).toBeInTheDocument();
    });

    test('renders with different button types', () => {
      renderButton({ type: 'submit' });

      const button = screen.getByRole('button');
      expect(button).toHaveAttribute('type', 'submit');
    });
  });

  describe('Variants', () => {
    test('applies primary variant classes by default', () => {
      renderButton();

      const button = screen.getByRole('button');
      expect(button).toHaveClass('bg-blue-600', 'text-white');
    });

    test('applies secondary variant classes', () => {
      renderButton({ variant: 'secondary' });

      const button = screen.getByRole('button');
      expect(button).toHaveClass('bg-gray-200', 'text-gray-900');
    });

    test('applies danger variant classes', () => {
      renderButton({ variant: 'danger' });

      const button = screen.getByRole('button');
      expect(button).toHaveClass('bg-red-600', 'text-white');
    });
  });

  describe('Sizes', () => {
    test('applies medium size classes by default', () => {
      renderButton();

      const button = screen.getByRole('button');
      expect(button).toHaveClass('px-4', 'py-2', 'text-base');
    });

    test('applies small size classes', () => {
      renderButton({ size: 'sm' });

      const button = screen.getByRole('button');
      expect(button).toHaveClass('px-3', 'py-2', 'text-sm');
    });

    test('applies large size classes', () => {
      renderButton({ size: 'lg' });

      const button = screen.getByRole('button');
      expect(button).toHaveClass('px-6', 'py-3', 'text-lg');
    });
  });

  describe('States', () => {
    test('handles disabled state', () => {
      renderButton({ disabled: true });

      const button = screen.getByRole('button');
      expect(button).toBeDisabled();
      expect(button).toHaveAttribute('aria-disabled', 'true');
      expect(button).toHaveClass('opacity-50', 'cursor-not-allowed');
    });

    test('handles loading state', () => {
      renderButton({ loading: true });

      const button = screen.getByRole('button');
      expect(button).toBeDisabled();
      expect(button).toHaveAttribute('aria-disabled', 'true');
      expect(button).toHaveClass('opacity-50', 'cursor-not-allowed');

      // Check for loading spinner
      expect(screen.getByTestId('loading-spinner')).toBeInTheDocument();
    });

    test('displays loading spinner when loading', () => {
      renderButton({ loading: true, children: 'Loading...' });

      expect(screen.getByTestId('loading-spinner')).toBeInTheDocument();
      expect(screen.getByText('Loading...')).toBeInTheDocument();
    });
  });

  describe('Click Handling', () => {
    test('calls onClick when clicked', async () => {
      const handleClick = jest.fn();
      const user = userEvent.setup();

      renderButton({ onClick: handleClick });

      const button = screen.getByRole('button');
      await user.click(button);

      expect(handleClick).toHaveBeenCalledTimes(1);
    });

    test('does not call onClick when disabled', async () => {
      const handleClick = jest.fn();
      const user = userEvent.setup();

      renderButton({ onClick: handleClick, disabled: true });

      const button = screen.getByRole('button');
      await user.click(button);

      expect(handleClick).not.toHaveBeenCalled();
    });

    test('does not call onClick when loading', async () => {
      const handleClick = jest.fn();
      const user = userEvent.setup();

      renderButton({ onClick: handleClick, loading: true });

      const button = screen.getByRole('button');
      await user.click(button);

      expect(handleClick).not.toHaveBeenCalled();
    });

    test('handles click with fireEvent', () => {
      const handleClick = jest.fn();

      renderButton({ onClick: handleClick });

      const button = screen.getByRole('button');
      fireEvent.click(button);

      expect(handleClick).toHaveBeenCalledTimes(1);
    });
  });

  describe('Custom Styling', () => {
    test('applies custom className', () => {
      const customClass = 'custom-button-class';
      renderButton({ className: customClass });

      const button = screen.getByRole('button');
      expect(button).toHaveClass(customClass);
    });

    test('combines custom className with default classes', () => {
      renderButton({ className: 'custom-class' });

      const button = screen.getByRole('button');
      expect(button).toHaveClass('custom-class');
      expect(button).toHaveClass('inline-flex'); // Default class
    });
  });

  describe('Accessibility', () => {
    test('has proper button role', () => {
      renderButton();

      const button = screen.getByRole('button');
      expect(button).toBeInTheDocument();
    });

    test('sets aria-disabled when disabled', () => {
      renderButton({ disabled: true });

      const button = screen.getByRole('button');
      expect(button).toHaveAttribute('aria-disabled', 'true');
    });

    test('sets aria-disabled when loading', () => {
      renderButton({ loading: true });

      const button = screen.getByRole('button');
      expect(button).toHaveAttribute('aria-disabled', 'true');
    });

    test('is focusable when not disabled', () => {
      renderButton();

      const button = screen.getByRole('button');
      button.focus();
      expect(button).toHaveFocus();
    });

    test('supports keyboard navigation', async () => {
      const handleClick = jest.fn();
      const user = userEvent.setup();

      renderButton({ onClick: handleClick });

      const button = screen.getByRole('button');
      button.focus();
      await user.keyboard('{Enter}');

      expect(handleClick).toHaveBeenCalledTimes(1);
    });
  });

  describe('Edge Cases', () => {
    test('handles undefined onClick gracefully', () => {
      renderButton({ onClick: undefined });

      const button = screen.getByRole('button');
      expect(() => fireEvent.click(button)).not.toThrow();
    });

    test('handles empty children', () => {
      renderButton({ children: '' });

      const button = screen.getByRole('button');
      expect(button).toBeInTheDocument();
      expect(button).toBeEmptyDOMElement();
    });

    test('handles complex children', () => {
      renderButton({
        children: (
          <span>
            <strong>Bold</strong> text
          </span>
        ),
      });

      expect(screen.getByText('Bold')).toBeInTheDocument();
      expect(screen.getByText('text')).toBeInTheDocument();
    });
  });
});
