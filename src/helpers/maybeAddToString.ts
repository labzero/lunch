export default (val: string | number, addend: number) =>
  (typeof val === "string" ? Number(val) : val) + addend;
