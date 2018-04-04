import singletons from '../singletons';
import waitOptions from './waitOptions';

export default async () => {
  const page = singletons.page;
  await page.goto('http://local.lunch.pink:3000/logout');
  await page.waitForSelector('#app', waitOptions);
};
