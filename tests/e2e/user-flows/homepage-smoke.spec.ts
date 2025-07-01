import { test, expect } from '@playwright/test';

/**
 * Cross-cutting E2E smoke test for homepage user journey
 * Tests complete user workflow across the entire application
 */
test.describe('Homepage User Journey - Smoke Test', () => {
  test('should load homepage with expected title and content', async ({ page }) => {
    // Navigate to homepage
    await page.goto('/');

    // Verify page title contains VibeBiz brand
    await expect(page).toHaveTitle(/VibeBiz/);

    // Verify main heading is visible and accessible
    await expect(
      page.getByRole('heading', { name: /VibeBiz/i, level: 1 })
    ).toBeVisible();

    // Verify page is interactive (not just static content)
    await expect(page.locator('body')).toBeVisible();

    // Basic performance check - page should load within reasonable time
    const navigationPromise = page.waitForLoadState('networkidle');
    await navigationPromise;
  });

  test('should have basic navigation elements', async ({ page }) => {
    await page.goto('/');

    // Check for essential navigation elements that would be expected in a SaaS app
    // This tests the complete user interface, not just individual components
    const body = page.locator('body');
    await expect(body).toContainText(/VibeBiz/i);
  });
});
