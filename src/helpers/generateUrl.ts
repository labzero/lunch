import { Request } from "express";

export default (req: Request, host: string, path = "") =>
  `${req.protocol}://${host}${path}`;
