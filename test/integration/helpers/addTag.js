import singletons from '../singletons';
import waitOptions from './waitOptions';

export default async () => {
  const page = singletons.page;
  await page.goto('http://integration-test.local.lunch.pink:3000/');
  await page.waitForSelector('.Restaurant-tagsArea button', waitOptions);
  await page.click('.Restaurant-tagsArea button');
  await page.waitForSelector('.RestaurantAddTagFormAutosuggest-container input', waitOptions);
  await page.type('.RestaurantAddTagFormAutosuggest-container input[type="text"]', 'waterfront');
  await page.click('.RestaurantAddTagForm-root button[type="submit"]');
  await page.waitForSelector('.Tag-root', waitOptions);
  await page.click('.RestaurantAddTagForm-root button[type="button"]');
  await page.waitForSelector('.Tag-root', waitOptions);
};
