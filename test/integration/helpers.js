import singletons from './singletons';

export const login = async () => {
	const page = singletons.page;
	await page.goto('http://local.lunch.pink:3000/login');
    await page.waitForSelector('#app');
	await page.type('#login-email', 'test@lunch.pink');
    await page.type('#login-password', 'test');
    await page.click('button[type="submit"]');
    await page.waitForSelector('.Teams-centerer .btn-default');
};

export const logout = async () => {
	const page = singletons.page;
	await page.goto('http://local.lunch.pink:3000/logout');
    await page.waitForSelector('#app');
};

export const createTeam = async () => {
	const page = singletons.page;
	await page.goto('http://local.lunch.pink:3000/new-team');
	await page.waitForSelector('#app');
	await page.type('#newTeam-name', 'test');
	await page.type('#newTeam-slug', 'integration-test');
	await page.type('#newTeam-address', '77 Battery Street, San Francisco, CA, USA');
	await page.click('button[type="submit"]');
	await page.waitForSelector('.list-group-item');
};

export const deleteTeam = async () => {
	const page = singletons.page;
	await page.goto('http://integration-test.local.lunch.pink:3000/team');
    await page.waitForSelector('.form-group');
	await page.click('#team-tabs-tab-3');
    await page.waitForSelector('.btn-danger');
    await page.click('.btn-danger');
	await page.type('#deleteTeamModal-confirmSlug', 'integration-test');
	await page.click('.modal-footer button[type="submit"]');
    await page.waitForSelector('.Teams-centerer .btn-default');
};

export const addRestaurant = async () => {
	const page = singletons.page;
	await page.goto('http://integration-test.local.lunch.pink:3000/');
    await page.waitForSelector('.geosuggest__input');
	await page.type('.geosuggest__input', 'ferry building');
    await page.waitForSelector('.geosuggest__item__matched-text');
    await page.click('li.RestaurantAddForm-suggestItemActive');
    await page.waitForSelector('.Restaurant-root');
};

export const deleteRestaurant = async () => {
	const page = singletons.page;
	await page.goto('http://integration-test.local.lunch.pink:3000/');
    await page.waitForSelector('.dropdown-toggle');
    await page.click('.dropdown-toggle');
    await page.waitForSelector('.dropdown.open');
    await page.click('ul.dropdown-menu li:nth-child(4)');
    await page.waitForSelector('.modal-open');
    await page.click('.modal-footer .btn-primary');
    await page.waitForSelector('.RestaurantList-welcome');
};

export const addTag = async () => {
	const page = singletons.page;
	await page.goto('http://integration-test.local.lunch.pink:3000/');
    await page.waitForSelector('.Restaurant-tagsArea button');
	await page.click('.Restaurant-tagsArea button');
    await page.waitForSelector('.RestaurantAddTagFormAutosuggest-container input');
    await page.type('.RestaurantAddTagFormAutosuggest-container input[type="text"]', 'waterfront');
    await page.click('.RestaurantAddTagForm-root button[type="submit"]');
    await page.waitForSelector('.Tag-root');
    await page.click('.RestaurantAddTagForm-root button[type="button"]');
    await page.waitForSelector('.Tag-root');
};

export const deleteTag = async () => {
	const page = singletons.page;
	await page.goto('http://integration-test.local.lunch.pink:3000/');
    await page.waitForSelector('button.Tag-button');
    await page.click('button.Tag-button');
    await page.waitForSelector('.Restaurant-tagsArea');
};