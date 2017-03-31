import React from 'react';
import LayoutContainer from '../../components/Layout/LayoutContainer';
import NotFound from '../notFound/NotFound';

const title = 'Page Not Found';

export default {
  title,
  component: <LayoutContainer><NotFound title={title} /></LayoutContainer>,
  status: 404,
};
