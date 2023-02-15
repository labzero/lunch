import React from 'react';
import withStyles from 'isomorphic-style-loader/withStyles';
import s from './HereMarker.scss';

const HereMarker = () => <div className={s.root} title="You are here" />;

export default withStyles(s)(HereMarker);
