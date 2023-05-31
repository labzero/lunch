import crypto from "crypto";

export default () =>
  new Promise((resolve, reject) => {
    crypto.randomBytes(20, (error, buf) => {
      if (error) {
        return reject(error);
      }
      return resolve(buf.toString("hex"));
    });
  });
