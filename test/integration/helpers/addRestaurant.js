import singletons from '../singletons';
import waitOptions from './waitOptions';

export default async () => {
  const page = singletons.page;
  const res = await page.goto('http://integration-test.local.lunch.pink:3000/');
  // eslint-disable-next-line no-console, no-unused-expressions
  res === null ? console.log('Null response encountered') : console.log('Successful `goto` command');
  await page.waitForSelector('.geosuggest__input', waitOptions);
  await page.type('.geosuggest__input', 'ferry building');
  await page.waitForSelector('.geosuggest__item__matched-text', waitOptions);
  await page.click('li.RestaurantAddForm-suggestItemActive');
  await page.waitForSelector('.Restaurant-root', waitOptions);
};
