/* eslint-env mocha */
/* eslint-disable no-unused-expressions */

import { expect } from 'chai';
import canChangeUser from '../canChangeUser';

describe('helpers/canChangeUser', () => {

	describe('canChangeUser', () => {
		let user;
		let userToChange;
		let team;
		let users;

		beforeEach(() => {
			user = {
				name: "dev", 
				id: 1, 
				superuser: false, 
				roles: [{type: "owner", team_id: 1, user_id: 1}],
				email: "dev@labzero.com"
			};
			userToChange = {
				name: "test", 
				id: 2,  
				type: "member", 
				email: "test@labzero.com"
			};
			team = {
				id: 1,
			};
			users = [
				{
					name: "dev", 
					id: 1, 
					type: "owner", 
					email: "dev@labzero.com"
				},
				{
					name: "test", 
					id: 2,  
					type: "member", 
					email: "test@labzero.com"
				}
			];
		});

		it('returns false when user is undefined', () => {
			user = undefined;
			expect(canChangeUser(user, userToChange, team, users)).to.be.false;
		});

		it('returns true when user is superuser', () => {
			user.superuser = true;
			expect(canChangeUser(user, userToChange, team, users)).to.be.true;
		});

		it('returns false when team is undefined', () => {
			team = undefined;
			expect(canChangeUser(user, userToChange, team, users)).to.be.false;
		});

		describe('when user role is owner and changing their own role', () => {
			beforeEach(() => {
				userToChange = {
					name: "dev", 
					id: 1,  
					type: "owner", 
					email: "dev@labzero.com"
				};
			});

			it('returns false when there are no other owners', () => {
				expect(canChangeUser(user, userToChange, team, users)).to.be.false;
			});

			it('returns true when there are other owners', () => {
				users[1].type = "owner";
				expect(canChangeUser(user, userToChange, team, users)).to.be.true;
			});

		});

		it('returns true when user role is owner and none of above conditions are met', () => {
			expect(canChangeUser(user, userToChange, team, users)).to.be.true;
		});
	});
});