import singletons from '../singletons';
import waitOptions from './waitOptions';

export default async () => {
  const page = singletons.page;
  const res = await page.goto('http://local.lunch.pink:3000/login');
    // eslint-disable-next-line no-console, no-unused-expressions, prefer-template
    console.log("*******************\n" + res + "\n");
  await page.waitForSelector('#app', waitOptions);
  await page.type('#login-email', 'test@lunch.pink');
  await page.type('#login-password', 'test');
  await page.click('button[type="submit"]');
  await page.waitForSelector('.Teams-centerer .btn-default', waitOptions);
};
