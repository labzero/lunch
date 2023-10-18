import formatDate from "./formatDate";

function runTask(task: (o?: string) => Promise<void>, options?: string) {
  // eslint-disable-next-line global-require
  const path = require("path");

  if (process.env.NODE_ENV === "test") {
    // eslint-disable-next-line global-require
    require("dotenv").config({
      path: path.resolve(process.cwd(), ".env.test"),
    });
  }

  // eslint-disable-next-line global-require
  require("dotenv").config();

  const start = new Date();
  console.info(
    `[${formatDate(start)}] Starting '${task.name}${
      options ? ` (${options})` : ""
    }'...`
  );
  return task(options).then((resolution) => {
    const end = new Date();
    const time = end.getTime() - start.getTime();
    console.info(
      `[${formatDate(end)}] Finished '${task.name}${
        options ? ` (${options})` : ""
      }' after ${time} ms`
    );
    return resolution;
  });
}

export default runTask;
