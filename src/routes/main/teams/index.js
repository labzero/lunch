import React from 'react';
import LayoutContainer from '../../../components/Layout/LayoutContainer';
import renderIfHasName from '../../helpers/renderIfHasName';
import TeamsContainer from './TeamsContainer';

/* eslint-disable global-require */

export default (context) => renderIfHasName(context, () => ({
  chunks: ['teams'],
  component: <LayoutContainer path={context.pathname}><TeamsContainer /></LayoutContainer>,
  title: 'My teams',
}));
