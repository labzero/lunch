export default (time: Date) =>
  time.toTimeString().replace(/.*(\d{2}:\d{2}:\d{2}).*/, "$1");
