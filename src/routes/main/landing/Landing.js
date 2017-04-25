import React from 'react';
import withStyles from 'isomorphic-style-loader/lib/withStyles';
import Button from 'react-bootstrap/lib/Button';
import Col from 'react-bootstrap/lib/Col';
import Grid from 'react-bootstrap/lib/Grid';
import Jumbotron from 'react-bootstrap/lib/Jumbotron';
import Row from 'react-bootstrap/lib/Row';
import search from './search.png';
import tag from './tag.png';
import vote from './vote.png';
import decide from './decide.png';
import s from './Landing.scss';

const Landing = () => (
  <div className={s.root}>
    <Jumbotron className={s.jumbotron}>
      <Grid>
        <h2 className={s.jumbotronHeading}>Figure it out,<br />together.</h2>
        <Row>
          <Col xs={12} sm={6} smOffset={6}>
            <p>
              Unsure what to eat?
              Want to leave the office for a bit and grab some grub with your team? Try Lunch!
            </p>
            <Button
              bsSize="large"
              bsStyle="primary"
              className={s.cta}
              href="/invitation/new"
            >
              Get invited
            </Button>
          </Col>
        </Row>
      </Grid>
    </Jumbotron>
    <Grid>
      <Row className={s.feature}>
        <Col xs={12} sm={6}>
          <img src={search} alt="" />
        </Col>
        <Col xs={12} sm={6}>
          <h3>Search!</h3>
          <p>Put together a list of nearby restaurants. You can add as many as you like.</p>
        </Col>
      </Row>
      <Row className={s.feature}>
        <Col xs={12} sm={6}>
          <img src={tag} alt="" />
        </Col>
        <Col xs={12} sm={6}>
          <h3>Tag!</h3>
          <p>Tag the restaurants, then filter or exclude certain kinds. Emoji tags? Go for it!</p>
        </Col>
      </Row>
      <Row className={s.feature}>
        <Col xs={12} sm={6}>
          <img src={vote} alt="" />
        </Col>
        <Col xs={12} sm={6}>
          <h3>Vote!</h3>
          <p>
            You only get one vote per restaurant each day, but you can vote for as many as you like.
            Voting also affects what shows up at the top of the list tomorrow!
          </p>
        </Col>
      </Row>
      <Row className={s.feature}>
        <Col xs={12} sm={6}>
          <img src={decide} alt="" />
        </Col>
        <Col xs={12} sm={6}>
          <h3>Decide!</h3>
          <p>
            When you mark a restaurant as the decision for the day, it’ll be sorted to
            the bottom of the list for the next few weeks to keep things fresh.
          </p>
        </Col>
      </Row>
    </Grid>
    <Grid>
      <div className={s.finalCta}>
        <h3>Already a member? Come on in!</h3>
        <Button bsSize="large" bsStyle="primary" className={s.cta} href="/login">
          Log into your teams
        </Button>
      </div>
    </Grid>
  </div>
);

export default withStyles(s)(Landing);
