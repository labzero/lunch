import React, { useState } from "react";
import ReCAPTCHA from "react-google-recaptcha";
import withStyles from "isomorphic-style-loader/withStyles";
import Button from "react-bootstrap/Button";
import Col from "react-bootstrap/Col";
import Form from "react-bootstrap/Form";
import Container from "react-bootstrap/Container";
import Row from "react-bootstrap/Row";
import submitRecaptchaForm from "../../helpers/submitRecaptchaForm";
import search from "./search.png";
import tag from "./tag.png";
import vote from "./vote.png";
import decide from "./decide.png";
import s from "./Landing.scss";

const action = "/invitation?success=sent";

const InvitationForm = ({ recaptchaSiteKey }: { recaptchaSiteKey: string }) => {
  const formRef = React.createRef();
  const recaptchaRef = React.createRef();

  const [email, setEmail] = useState("");

  const handleSubmit = async (event: React.TargetedEvent<HTMLFormElement>) => {
    event.preventDefault();

    const token = await recaptchaRef.current.executeAsync();

    submitRecaptchaForm(action, {
      email,
      "g-recaptcha-response": token,
    });
  };

  return (
    <Form
      className={s.form}
      action={action}
      method="post"
      onSubmit={handleSubmit}
      ref={formRef}
    >
      <ReCAPTCHA
        ref={recaptchaRef}
        size="invisible"
        sitekey={recaptchaSiteKey}
      />
      <Form.Group className={s.formGroup} controlId="landing-email">
        <Form.Label visuallyHidden>Email</Form.Label>
        <Form.Control
          size="lg"
          className={s.field}
          name="email"
          onChange={(event) => setEmail(event.currentTarget.value)}
          placeholder="Enter your email"
          required
          type="email"
        />
      </Form.Group>{" "}
      <Button size="lg" variant="primary" type="submit">
        Get invited
      </Button>
    </Form>
  );
};

const Landing = ({ recaptchaSiteKey }: { recaptchaSiteKey: string }) => (
  <div className={s.root}>
    <section className={s.jumbotron}>
      <Container>
        <h2 className={s.jumbotronHeading}>
          Figure it out,
          <br />
          together.
        </h2>
        <Row>
          <Col xs={12} sm={{ span: 6, offset: 3 }}>
            <p>
              Unsure what to eat? Want to leave the office for a bit and grab
              some grub with your team? Try&nbsp;Lunch!
            </p>
            <InvitationForm recaptchaSiteKey={recaptchaSiteKey} />
          </Col>
        </Row>
      </Container>
    </section>
    <Container>
      <Row className={s.feature}>
        <Col xs={12} sm={6}>
          <img src={search} alt="" />
        </Col>
        <Col xs={12} sm={6}>
          <h3>Search!</h3>
          <p>
            Put together a list of nearby restaurants. You can add as many as
            you like.
          </p>
        </Col>
      </Row>
      <Row className={s.feature}>
        <Col xs={12} sm={6}>
          <img src={tag} alt="" />
        </Col>
        <Col xs={12} sm={6}>
          <h3>Tag!</h3>
          <p>
            Tag the restaurants, then filter or exclude certain kinds. Emoji
            tags? Go for it!
          </p>
        </Col>
      </Row>
      <Row className={s.feature}>
        <Col xs={12} sm={6}>
          <img src={vote} alt="" />
        </Col>
        <Col xs={12} sm={6}>
          <h3>Vote!</h3>
          <p>
            You only get one vote per restaurant each day, but you can vote for
            as many as you like. Voting also affects what shows up at the top of
            the list tomorrow!
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
            When you mark a restaurant as the decision for the day, it’ll be
            sorted to the bottom of the list for the next few weeks to keep
            things fresh.
          </p>
        </Col>
      </Row>
    </Container>
    <Container>
      <div className={s.finalCta}>
        <h3>Sign up today!</h3>
        <Row>
          <Col xs={12} sm={{ span: 6, offset: 3 }}>
            <InvitationForm recaptchaSiteKey={recaptchaSiteKey} />
          </Col>
        </Row>
      </div>
      <div className={s.finalCta}>
        <h3>Already a member? Come on in!</h3>
        <Button size="lg" variant="primary" href="/login">
          Log into your teams
        </Button>
      </div>
    </Container>
  </div>
);

export default withStyles(s)(Landing);
