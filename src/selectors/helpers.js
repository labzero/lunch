export const makeWrapper = selector => state => props => selector(state, props);
export const returnProps = (state, props) => props;
