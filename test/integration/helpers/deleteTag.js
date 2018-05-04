import singletons from '../singletons';
import waitOptions from './waitOptions';

export default async () => {
  const page = singletons.page;
  const res = await page.goto('http://integration-test.local.lunch.pink:3000/');
    // eslint-disable-next-line no-console, no-unused-expressions
    res === null ? console.log('Null response encountered') : console.log('Successful `goto` command');
  await page.waitForSelector('button.Tag-button', waitOptions);
  await page.click('button.Tag-button');
  await page.waitForSelector('.Restaurant-tagsArea', waitOptions);
};
