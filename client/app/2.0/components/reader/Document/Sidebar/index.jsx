// External Dependencies
import React from 'react';
import PropTypes from 'prop-types';
import classNames from 'classnames';

// Internal Dependencies
import Button from 'app/components/Button';
import { sidebarWrapper } from 'styles/reader/Document/Sidebar';

import { DocumentAccordion } from 'components/reader/Document/Sidebar/Accordion';
import { KeyboardInfo } from 'components/reader/Document/Sidebar/KeyboardInfo';

/**
 * Document Sidebar Component
 * @param {Object} props -- Contains details about showing/hiding the sidebar and passes props through
 */
export const DocumentSidebar = ({ hidePdfSidebar, togglePdfSidebar, modal, ...props }) => (
  <div className={classNames('cf-sidebar-wrapper', { 'hidden-sidebar': hidePdfSidebar })} {...sidebarWrapper}>
    <div className="cf-sidebar-header">
      <Button name="hide menu" classNames={['cf-pdf-button']} id="hide-menu-header" onClick={togglePdfSidebar}>
        <h2 className="cf-non-stylized-header">
          Hide menu <i className="fa fa-chevron-right" aria-hidden="true"></i>
        </h2>
      </Button>
    </div>
    <DocumentAccordion {...props} />
    <KeyboardInfo show={modal} {...props} />
  </div>
);

DocumentSidebar.propTypes = {
  hidePdfSidebar: PropTypes.bool,
  togglePdfSidebar: PropTypes.func,
  featureToggles: PropTypes.object,
  openedAccordionSections: PropTypes.array,
  commentListRef: PropTypes.element,
  toggleAccordion: PropTypes.func,
  appeal: PropTypes.object,
  doc: PropTypes.object,
  openKeyboardModal: PropTypes.func,
  modal: PropTypes.bool,
  closeKeyboardModalFromButton: PropTypes.func,
  handleKeyboardModalClose: PropTypes.func,
};
