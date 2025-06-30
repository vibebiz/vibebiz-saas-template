import { test, expect } from '@playwright/test';
import AxeBuilder from '@axe-core/playwright';

test.describe('accessibility tests', () => {
  test('the home page should not have any automatically detectable accessibility issues', async ({
    page,
  }) => {
    await page.goto('/');

    const accessibilityScanResults = await new AxeBuilder({ page })
      .withRules(['button-name'])
      .analyze();

    expect(accessibilityScanResults.violations).toEqual([]);
  });
});
