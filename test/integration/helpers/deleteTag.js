// import singletons from '../singletons';
import waitOptions from './waitOptions';

export default async (page) => {
  // const page = singletons.page;
  const res = await page.goto('http://integration-test.local.lunch.pink:3000/');
    // eslint-disable-next-line no-console, no-unused-expressions, prefer-template
    console.log("*******************\nDeleted tag");
    // eslint-disable-next-line no-console, no-unused-expressions, prefer-template
    console.log(res);    
  await page.waitForSelector('button.Tag-button', waitOptions);
  await page.click('button.Tag-button');
  await page.waitForSelector('.Restaurant-tagsArea', waitOptions);
};
