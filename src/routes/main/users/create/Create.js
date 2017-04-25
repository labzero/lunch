import React from 'react';
import withStyles from 'isomorphic-style-loader/lib/withStyles';
import Grid from 'react-bootstrap/lib/Grid';
import s from './Create.scss';

const Create = () => (
  <Grid className={s.root}>
    <h2>Success</h2>
    <p>User created.</p>
  </Grid>
);

export default withStyles(s)(Create);
