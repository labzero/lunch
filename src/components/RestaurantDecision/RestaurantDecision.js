import React, { PropTypes } from 'react';
import withStyles from 'isomorphic-style-loader/lib/withStyles';
import s from './RestaurantDecision.scss';

const RestaurantDecision = ({ decided }) => <button className={`${s.root} ${decided ? s.decided : ''}`}>✔</button>;

export default withStyles(RestaurantDecision, s);
