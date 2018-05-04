import singletons from '../singletons';
import waitOptions from './waitOptions';

export default async () => {
  const page = singletons.page;
  const res = await page.goto('http://local.lunch.pink:3000/new-team');
    // eslint-disable-next-line no-console, no-unused-expressions
    res === null ? console.log('Null response encountered') : console.log('Successful `goto` command');
  await page.waitForSelector('#app', waitOptions);
  await page.type('#newTeam-name', 'test');
  await page.type('#newTeam-slug', 'integration-test');
  await page.type('#newTeam-address', '77 Battery Street, San Francisco, CA, USA');
  await page.click('button[type="submit"]');
  await page.waitForSelector('.list-group-item', waitOptions);
};
