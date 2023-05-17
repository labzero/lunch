import { Router } from "express";
import querystring from "querystring";
import { bsHost } from "../config";
import generateToken from "../helpers/generateToken";
import generateUrl from "../helpers/generateUrl";
import { Invitation, Role, User } from "../models";
import transporter from "../mailers/transporter";

const sendConfirmation = async (req, email, token) => {
  await transporter.sendMail({
    email,
    subject: "Confirm your email for an invitation",
    text: `Hi there,

Thanks for signing up for an invitation to Lunch. To confirm that you're interested, please visit this URL:
${generateUrl(req, bsHost, `/invitation?token=${token}`)}

Hope to see you on Lunch soon!`,
  });
};

export default () => {
  const router = new Router();

  return router
    .get("/", async (req, res, next) => {
      const { token } = req.query;

      if (token) {
        try {
          const invitation = await Invitation.findOne({
            where: { confirmationToken: token },
          });

          if (invitation) {
            if (invitation.get("confirmedAt")) {
              next();
            } else {
              await invitation.update({
                confirmedAt: new Date(),
              });
              const recipients = await User.findAll({
                where: { superuser: true },
                include: [Role],
              });
              const firstSuperuser = recipients[0];
              if (firstSuperuser) {
                await transporter.sendMail({
                  recipients,
                  subject: "Invitation request",
                  text: `${invitation.email} would like to be invited.
                      
Add them here: ${generateUrl(
                    req,
                    bsHost,
                    `/users/new?email=${querystring.escape(invitation.email)}`
                  )}`,
                });
              }
              next();
            }
          } else {
            res.redirect("/invitation/new");
          }
        } catch (err) {
          next(err);
        }
      } else {
        res.redirect("/invitation/new");
      }
    })
    .post("/", async (req, res, next) => {
      const { email } = req.body;

      try {
        if (!email) {
          req.flash("error", "Email is required.");
          return req.session.save(() => {
            res.redirect("/invitation/new");
          });
        }

        const existingInvitation = await Invitation.findOne({
          where: { email },
        });

        if (existingInvitation) {
          if (existingInvitation.get("confirmedAt")) {
            req.flash(
              "error",
              "You've already confirmed your invitation request. Please be patient!"
            );
            return req.session.save(() => {
              res.redirect("/invitation/new");
            });
          }
          const confirmationSentAt =
            existingInvitation.get("confirmationSentAt");
          if (
            confirmationSentAt &&
            Date.now() - confirmationSentAt < 60 * 60 * 1000 * 24
          ) {
            req.flash(
              "error",
              "You've already submitted an invitation request. Check your email for a confirmation URL. If you don't see one, check your spam folder or submit again in 24 hours."
            );
            return req.session.save(() => {
              res.redirect("/invitation/new");
            });
          }
          await sendConfirmation(req, email, existingInvitation.get("token"));
          await existingInvitation.update({
            confirmationSentAt: new Date(),
          });
          req.flash(
            "success",
            "We've resent an email to confirm your invitation request. Check your spam folder if you don't see it."
          );
          return req.session.save(() => {
            next();
          });
        }

        const confirmationToken = await generateToken();

        Invitation.create({
          email,
          confirmationToken,
          confirmationSentAt: new Date(),
        });

        await sendConfirmation(req, email, confirmationToken);
        return next();
      } catch (err) {
        return next(err);
      }
    });
};
