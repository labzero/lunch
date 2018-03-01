import React from 'react';
import withStyles from 'isomorphic-style-loader/lib/withStyles';
import Grid from 'react-bootstrap/lib/Grid';
import s from './Create.scss';

const Create = () => (
  <div className={s.root}>
    <Grid>
      <h2>Success</h2>
      <p>User created.</p>
    </Grid>
  </div>
);

export default withStyles(s)(Create);
