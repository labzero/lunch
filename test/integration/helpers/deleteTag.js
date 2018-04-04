import singletons from '../singletons';
import waitOptions from './waitOptions';

export default async () => {
  const page = singletons.page;
  await page.goto('http://integration-test.local.lunch.pink:3000/');
  await page.waitForSelector('button.Tag-button', waitOptions);
  await page.click('button.Tag-button');
  await page.waitForSelector('.Restaurant-tagsArea', waitOptions);
};
