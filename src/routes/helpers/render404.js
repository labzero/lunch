import React from 'react';
import LayoutContainer from '../../components/Layout/LayoutContainer';
import NotFound from '../not-found/NotFound';

const title = 'Page Not Found';

export default {
  chunks: ['not-found'],
  title,
  component: <LayoutContainer><NotFound title={title} /></LayoutContainer>,
  status: 404,
};
