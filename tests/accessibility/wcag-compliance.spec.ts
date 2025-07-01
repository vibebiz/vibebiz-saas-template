import { test, expect } from '@playwright/test';
import AxeBuilder from '@axe-core/playwright';

/**
 * Cross-cutting accessibility tests for WCAG 2.2 AA compliance
 * Tests system-wide accessibility across the entire application
 */
test.describe('WCAG 2.2 AA Compliance - System-wide Accessibility', () => {
  test('homepage should meet WCAG 2.2 AA accessibility standards', async ({ page }) => {
    await page.goto('/');

    // Run comprehensive accessibility scan
    const accessibilityScanResults = await new AxeBuilder({ page })
      .withTags(['wcag2a', 'wcag2aa', 'wcag21aa', 'wcag22aa'])
      .analyze();

    // Ensure no accessibility violations
    expect(accessibilityScanResults.violations).toEqual([]);

    // Log any incomplete tests that need manual review
    if (accessibilityScanResults.incomplete?.length > 0) {
      console.log(
        'Incomplete accessibility tests requiring manual review:',
        accessibilityScanResults.incomplete
      );
    }
  });

  test('should have proper keyboard navigation support', async ({ page }) => {
    await page.goto('/');

    // Test keyboard navigation - essential for accessibility
    await page.keyboard.press('Tab');

    // Verify focus is visible and properly managed
    const focusedElement = await page.locator(':focus');
    await expect(focusedElement).toBeVisible();
  });

  test('should have proper color contrast ratios', async ({ page }) => {
    await page.goto('/');

    // Run specific color contrast tests
    const accessibilityScanResults = await new AxeBuilder({ page })
      .withTags(['color-contrast'])
      .analyze();

    expect(accessibilityScanResults.violations).toEqual([]);
  });

  test('should have proper ARIA labels and semantic markup', async ({ page }) => {
    await page.goto('/');

    // Test for proper ARIA implementation
    const accessibilityScanResults = await new AxeBuilder({ page })
      .withTags(['best-practice'])
      .analyze();

    expect(accessibilityScanResults.violations).toEqual([]);
  });
});
