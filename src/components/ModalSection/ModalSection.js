import React, { PropTypes } from 'react';
import ConfirmModalContainer from '../ConfirmModal/ConfirmModalContainer';
import DeleteRestaurantModalContainer from '../DeleteRestaurantModal/DeleteRestaurantModalContainer';
import DeleteTagModalContainer from '../DeleteTagModal/DeleteTagModalContainer';
import DeleteTeamModalContainer from '../DeleteTeamModal/DeleteTeamModalContainer';

const ModalSection = ({ modals }) => {
  const modalContainers = [];
  if (modals.confirm !== undefined) {
    modalContainers.push(<ConfirmModalContainer key="modalContainer_confirm" />);
  }
  if (modals.deleteRestaurant !== undefined) {
    modalContainers.push(<DeleteRestaurantModalContainer key="modalContainer_deleteRestaurant" />);
  }
  if (modals.deleteTag !== undefined) {
    modalContainers.push(<DeleteTagModalContainer key="modalContainer_deleteTag" />);
  }
  if (modals.deleteTeam !== undefined) {
    modalContainers.push(<DeleteTeamModalContainer key="modalContainer_deleteTeam" />);
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
