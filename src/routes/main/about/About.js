import React from 'react';
import withStyles from 'isomorphic-style-loader/withStyles';
import Container from 'react-bootstrap/Container';
import s from './About.scss';

const About = () => (
  <div className={s.root}>
    <Container className={s.grid}>
      <h2>About Lunch</h2>
      <p>
        Hi! I’m
        {' '}
        <a
          href="https://jeffreyatw.com"
          rel="noopener noreferrer"
          target="_blank"
        >
          Jeffrey
        </a>
        , the guy behind Lunch. I created Lunch when my coworkers at
        {' '}
        <a href="https://labzero.com" rel="noopener noreferrer" target="_blank">
          Lab Zero
        </a>
        {' '}
        realized we had fallen into sort of a rut, food-wise. We kept going to
        the same few places, and our routine was getting stale. So I made Lunch,
        an easy way to keep a list of our favorite restaurants, and decide where
        to go!
      </p>
      <p>
        It’s worked great for us. Every day around 10:30 (we eat early to beat
        the crowds), we all hop on Lunch and vote for whatever looks good.
        Eventually, a consensus is reached, and we’re on our way. That, or a
        whole bunch of places are tied for votes, and so we just, y’know, talk
        it over like humans.
      </p>
      <p>
        Either way, I hope you have fun using Lunch! I think it’s helped us grow
        closer as coworkers, because we’re more invested in trying new places
        together, and making sure we leave the office for a little bit each day.
        Hot tip: set up a reminder in Slack to vote where to go every day!
      </p>
      <pre className={s.slackSnippet}>
        /remind #general &quot;Vote for lunch! https://lunch.pink&quot; at
        10:30am every weekday
      </pre>
      <h3 id="privacy">Privacy</h3>
      <p>
        I haven’t talked to a lawyer, but I should probably reassure you about
        what might happen with your data when you sign up.
      </p>
      <h4>Open-source</h4>
      <p>
        First of all, Lunch is
        {' '}
        <a
          href="https://github.com/labzero/lunch"
          rel="noopener noreferrer"
          target="_blank"
        >
          open-source and available on GitHub
        </a>
        . If you’re ever doubtful about what we’re doing with stuff like your
        email address or your team’s daily decisions, you can have a look
        yourself.
      </p>
      <h4>Storing your data</h4>
      <p>
        Public sign-ups for Lunch are currently closed. If you try to log in
        with your Google account and you don’t already have a Lunch account, I’m
        not going to store any of your data, or keep a record that you even
        tried to log in &mdash; but you will be prompted to sign up for an
        invitation.
      </p>
      <p>
        For those who are already Lunch users, when you link a Google account I
        only store your email address, your name, and your Google profile ID.
      </p>
      <h4>Email use</h4>
      <p>
        I only plan on sending email for stuff like password resets and
        notifications that you’ve been added to a new team. I’m certainly not
        interested in using your email address for any reason other than to
        identify you when you log in. On Lunch, the only people who can see your
        email address are owners of the teams you’re a part of.
      </p>
      <h4>Cookies</h4>
      <p>
        Like pretty much any website with a login, Lunch will tell your browser
        to hold onto a cookie that identifies you as being logged in. There’s
        also a separate “session” cookie that makes sure you’re the same person
        from page to page, so you can see success or failure messages when doing
        things like requesting a password reset.
      </p>
      <h4>Google Analytics</h4>
      <p>
        This site also uses
        {' '}
        <a
          href="https://analytics.google.com/"
          rel="noopener noreferrer"
          target="_blank"
        >
          Google Analytics
        </a>
        {' '}
        to give me an idea of what sorts of people are using Lunch, and from
        where.
        {' '}
        <a
          href="https://support.google.com/analytics/answer/6004245?hl=en"
          rel="noopener noreferrer"
          target="_blank"
        >
          You can read more about their own policies
        </a>
        , which are pretty standard (they store a few cookies as well), but it’s
        worth pointing out that the tracking is anonymous &mdash; there’s no way
        they or I can tell exactly who you are.
      </p>
      <h4>Cost</h4>
      <p>
        Lunch is currently free. Unlimited users per team, and each user can
        create or be a part of up to three teams. I don’t plan on putting any
        limitations on what’s currently offered, but I might consider charging
        for future features, whatever those might be. Either way, I haven’t even
        set up a way for you to give me money, so I wouldn’t worry about it.
      </p>
      <h4>Advertising</h4>
      <p>
        That said, I’m not against advertisements, or sponsored list items, or
        something of the sort. If I do reach out to restaurants to advertise on
        Lunch, I’d display tasteful advertisements based on their proximity to
        your team. I wouldn’t give advertisers info like the specific names of
        teams, or the people on it, or anything “personally identifiable” like
        that. Again, this is all just potential stuff in the future, so it’s
        just a heads up for now.
      </p>
      <h4>Be excellent to each other</h4>
      <p>
        Oh and finally, don’t be mean to your teammates. I don’t think there’s
        any need for global moderation on a service this limited, but like,
        don’t tag restaurants as “disgusting” or delete places you don’t like.
        Just don’t vote for them. Otherwise, your team owner’s totally free to
        kick you out.
      </p>
      <p>
        Any other questions or things I forgot to mention? Drop me a line at
        {' '}
        <a href="mailto:jeffrey@labzero.com">jeffrey@labzero.com</a>
        . I’d be
        happy to hear from you.
      </p>
      <p>I last updated this page on May 1, 2017.</p>
    </Container>
  </div>
);

export default withStyles(s)(About);
