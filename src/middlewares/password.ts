import { Router } from "express";
import { bsHost } from "../config";
import generateToken from "../helpers/generateToken";
import generateUrl from "../helpers/generateUrl";
import getPasswordError from "../helpers/getPasswordError";
import getUserPasswordUpdates from "../helpers/getUserPasswordUpdates";
import transporter from "../mailers/transporter";
import { User } from "../db";

export default () => {
  const router = Router();

  router
    .post("/", async (req, res, next) => {
      try {
        const user = await User.findOne({ where: { email: req.body.email } });
        if (user) {
          const resetPasswordToken = await generateToken();
          await user.update({
            resetPasswordToken,
            resetPasswordSentAt: new Date(),
          });
          await transporter.sendMail({
            name: user.name,
            email: user.email,
            subject: "Password reset instructions",
            text: `Hi there!

A password reset link was requested for your account. If you'd like to enter a new password, do so here: 
${generateUrl(req, bsHost, `/password/edit?token=${resetPasswordToken}`)}
This link will expire in one day.

Happy Lunching!`,
          });
        }
        next();
      } catch (err) {
        next(err);
      }
    })
    .put("/", async (req, res, next) => {
      try {
        const user = await User.findOne({
          where: { resetPasswordToken: req.body.token },
        });
        if (!user || !user.resetPasswordValid()) {
          res.redirect("/password/new");
        } else {
          const passwordError = getPasswordError(req.body.password);
          if (passwordError) {
            req.flash("error", passwordError);
            req.session.save(() => {
              res.redirect(`/password/edit?token=${req.body.token}`);
            });
          } else {
            const updates = await getUserPasswordUpdates(
              user,
              req.body.password
            );
            await user.update(updates);
            next();
          }
        }
      } catch (err) {
        next(err);
      }
    })
    .get("/edit", async (req, res, next) => {
      try {
        const user = await User.findOne({
          where: { resetPasswordToken: req.query.token },
        });
        if (!user || !user.resetPasswordValid()) {
          res.redirect("/password/new");
        } else {
          next();
        }
      } catch (err) {
        next(err);
      }
    });

  return router;
};
