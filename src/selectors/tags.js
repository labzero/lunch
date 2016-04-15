export const getTagEntities = state => state.tags.items.entities.tags;
export const getTagById = (state, props) => getTagEntities(state)[typeof props === 'object' ? props.tagId : props];
