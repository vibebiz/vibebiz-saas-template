import { test, expect } from '@playwright/test';

test('homepage has expected title and heading', async ({ page }) => {
  await page.goto('/');

  // Expect a title "to contain" a substring.
  await expect(page).toHaveTitle(/VibeBiz/);

  // Expect a heading to be visible.
  await expect(page.getByRole('heading', { name: /VibeBiz/i, level: 1 })).toBeVisible();
});
