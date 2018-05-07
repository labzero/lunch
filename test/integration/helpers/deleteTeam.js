import singletons from '../singletons';
import waitOptions from './waitOptions';

export default async () => {
  const page = singletons.page;
  const res = await page.goto('http://integration-test.local.lunch.pink:3000/team');
    // eslint-disable-next-line no-console, no-unused-expressions, prefer-template
    console.log("*******************\n" + res + "\n");
  await page.waitForSelector('.form-group', waitOptions);
  await page.click('#team-tabs-tab-3');
  await page.waitForSelector('.btn-danger', waitOptions);
  await page.click('.btn-danger');
  await page.type('#deleteTeamModal-confirmSlug', 'integration-test');
  await page.click('.modal-footer button[type="submit"]');
  await page.waitForSelector('.Teams-centerer .btn-default', waitOptions);
};
