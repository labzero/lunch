module.exports = {
  up: (queryInterface) => {
    queryInterface.addIndex('decisions', ['created_at']);
    queryInterface.addIndex('decisions', ['restaurant_id']);
    queryInterface.addIndex('restaurants_tags', ['restaurant_id']);
    queryInterface.addIndex('restaurants_tags', ['tag_id']);
    queryInterface.addIndex('roles', ['team_id']);
    queryInterface.addIndex('roles', ['user_id']);
    queryInterface.addIndex('teams', ['created_at']);
    queryInterface.addIndex('votes', ['created_at']);
    queryInterface.addIndex('votes', ['restaurant_id']);
    queryInterface.addIndex('votes', ['user_id']);
  },

  down: (queryInterface) => {
    queryInterface.removeIndex('decisions', 'decisions_created_at');
    queryInterface.removeIndex('decisions', 'decisions_restaurant_id');
    queryInterface.removeIndex('restaurants_tags', 'restaurants_tags_restaurant_id');
    queryInterface.removeIndex('restaurants_tags', 'restaurants_tags_tag_id');
    queryInterface.removeIndex('roles', 'roles_team_id');
    queryInterface.removeIndex('roles', 'roles_user_id');
    queryInterface.removeIndex('teams', 'teams_created_at');
    queryInterface.removeIndex('votes', 'votes_created_at');
    queryInterface.removeIndex('votes', 'votes_restaurant_id');
    queryInterface.removeIndex('votes', 'votes_user_id');
  }
};
