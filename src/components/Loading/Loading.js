import React from 'react';
import withStyles from 'isomorphic-style-loader/withStyles';
import s from './Loading.scss';

const Loading = () => (
  <div className={s.root}>
    <div>
      <div />
    </div>
    <div>
      <div />
    </div>
    <div>
      <div />
    </div>
    <div>
      <div />
    </div>
    <div>
      <div />
    </div>
  </div>
);

export default withStyles(s)(Loading);
