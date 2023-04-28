import React from 'react';
import withStyles from 'isomorphic-style-loader/withStyles';
import Container from 'react-bootstrap/Container';
import s from './Create.scss';

const Create = () => (
  <div className={s.root}>
    <Container>
      <h2>Success</h2>
      <p>User created.</p>
    </Container>
  </div>
);

export default withStyles(s)(Create);
