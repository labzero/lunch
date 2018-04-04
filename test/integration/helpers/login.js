import singletons from '../singletons';
import waitOptions from './waitOptions';

export default async () => {
  const page = singletons.page;
  await page.goto('http://local.lunch.pink:3000/login');
  await page.waitForSelector('#app', waitOptions);
  await page.type('#login-email', 'test@lunch.pink');
  await page.type('#login-password', 'test');
  await page.click('button[type="submit"]');
  await page.waitForSelector('.Teams-centerer .btn-default', waitOptions);
};
