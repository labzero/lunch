import React, { PropTypes } from 'react';
import RestaurantsPageContainer from '../../../../containers/RestaurantsPageContainer';
import LoginPageContainer from '../../../../containers/LoginPageContainer';

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
