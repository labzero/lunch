import singletons from '../singletons';
import waitOptions from './waitOptions';

export default async () => {
  const page = singletons.page;
  await page.goto('http://integration-test.local.lunch.pink:3000/team');
  await page.waitForSelector('.form-group', waitOptions);
  await page.click('#team-tabs-tab-3');
  await page.waitForSelector('.btn-danger', waitOptions);
  await page.click('.btn-danger');
  await page.type('#deleteTeamModal-confirmSlug', 'integration-test');
  await page.click('.modal-footer button[type="submit"]');
  await page.waitForSelector('.Teams-centerer .btn-default', waitOptions);
};
