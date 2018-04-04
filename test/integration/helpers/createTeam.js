import singletons from '../singletons';
import waitOptions from './waitOptions';

export default async () => {
  const page = singletons.page;
  await page.goto('http://local.lunch.pink:3000/new-team');
  await page.waitForSelector('#app', waitOptions);
  await page.type('#newTeam-name', 'test');
  await page.type('#newTeam-slug', 'integration-test');
  await page.type('#newTeam-address', '77 Battery Street, San Francisco, CA, USA');
  await page.click('button[type="submit"]');
  await page.waitForSelector('.list-group-item', waitOptions);
};
