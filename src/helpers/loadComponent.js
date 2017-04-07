export default async (requireCall) => {
  try {
    return await requireCall();
  } catch (err) {
    return () => null;
  }
};
