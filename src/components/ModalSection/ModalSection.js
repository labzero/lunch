import React, { PropTypes } from 'react';
import DeleteRestaurantModalContainer from '../DeleteRestaurantModal/DeleteRestaurantModalContainer';
import TagManagerModalContainer from '../TagManagerModal/TagManagerModalContainer';
import DeleteTagModalContainer from '../DeleteTagModal/DeleteTagModalContainer';
import EmailWhitelistModalContainer from '../EmailWhitelistModal/EmailWhitelistModalContainer';

const ModalSection = ({ modals }) => {
  const modalContainers = [];
  if (modals.deleteRestaurant !== undefined) {
    modalContainers.push(<DeleteRestaurantModalContainer key="modalContainer_deleteRestaurant" />);
  }
  if (modals.tagManager !== undefined) {
    modalContainers.push(<TagManagerModalContainer key="modalContainer_tagManager" />);
  }
  if (modals.deleteTag !== undefined) {
    modalContainers.push(<DeleteTagModalContainer key="modalContainer_deleteTag" />);
  }
  if (modals.emailWhitelist !== undefined) {
    modalContainers.push(<EmailWhitelistModalContainer key="modalContainer_emailWhitelist" />);
  }

  return (
    <div>
      {modalContainers}
    </div>
  );
};

ModalSection.propTypes = {
  modals: PropTypes.object.isRequired
};

export default ModalSection;
