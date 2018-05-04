import singletons from '../singletons';
import waitOptions from './waitOptions';

export default async () => {
  const page = singletons.page;
  const res = await page.goto('http://integration-test.local.lunch.pink:3000/');
    // eslint-disable-next-line no-console, no-unused-expressions, prefer-template
    console.log("*******************\n" + res + "\n");
  await page.waitForSelector('.dropdown-toggle', waitOptions);
  await page.click('.dropdown-toggle');
  await page.waitForSelector('.dropdown.open', waitOptions);
  await page.click('ul.dropdown-menu li:nth-child(4)');
  await page.waitForSelector('.modal-open', waitOptions);
  await page.click('.modal-footer .btn-primary');
  await page.waitForSelector('.RestaurantList-welcome', waitOptions);
};
