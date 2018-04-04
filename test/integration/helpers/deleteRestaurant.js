import singletons from '../singletons';
import waitOptions from './waitOptions';

export default async () => {
  const page = singletons.page;
  await page.goto('http://integration-test.local.lunch.pink:3000/');
  await page.waitForSelector('.dropdown-toggle', waitOptions);
  await page.click('.dropdown-toggle');
  await page.waitForSelector('.dropdown.open', waitOptions);
  await page.click('ul.dropdown-menu li:nth-child(4)');
  await page.waitForSelector('.modal-open', waitOptions);
  await page.click('.modal-footer .btn-primary');
  await page.waitForSelector('.RestaurantList-welcome', waitOptions);
};
