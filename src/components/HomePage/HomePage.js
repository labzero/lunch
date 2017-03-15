import React, { PropTypes } from 'react';
import RestaurantsPageContainer from '../RestaurantsPage/RestaurantsPageContainer';
import LoginPageContainer from '../LoginPage/LoginPageContainer';

const HomePage = ({ loggedIn }) => {
  if (loggedIn) {
    return <RestaurantsPageContainer />;
  }
  return <LoginPageContainer />;
};

HomePage.propTypes = {
  loggedIn: PropTypes.bool.isRequired
};

export default HomePage;
