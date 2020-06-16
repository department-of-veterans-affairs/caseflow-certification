import React, { useRef, useContext } from 'react';
import PropTypes from 'prop-types';

import cx from 'classnames';
import { TabContext } from './TabContext';

const propTypes = {
  as: PropTypes.elementType,
  className: PropTypes.string,
  children: PropTypes.arrayOf(PropTypes.element).isRequired,
  fullWidth: PropTypes.bool,
  keyNav: PropTypes.bool,
};

export const TabList = ({
  as: Component = 'div',
  className = '',
  fullWidth = false,
  keyNav = true,
  ...props
}) => {
  const ctx = useContext(TabContext);
  const tabListRef = useRef(null);

  const handleKeyDown = (event) => {
    // Keyboard navigation is technically optional, but is important for accessibility
    if (!keyNav) {
      return;
    }

    const { target } = event;

    // Keyboard navigation assumes that [role="tab"] are siblings
    // though we might warn in the future about nested, interactive elements
    // as a a11y violation
    const role = target.getAttribute('role');

    if (role !== 'tab') {
      return;
    }

    const PREV_KEY = 'ArrowLeft';
    const NEXT_KEY = 'ArrowRight';

    let newFocusTarget = null;

    // Look for the appropriate next element, but stay put if at first or last
    switch (event.key) {
    case PREV_KEY:
      newFocusTarget = target.previousElementSibling || target;
      break;
    case NEXT_KEY:
      newFocusTarget = target.nextElementSibling || target;
      break;
    default:
      break;
    }

    if (newFocusTarget !== null && !newFocusTarget.disabled) {
      newFocusTarget.focus();
      event.preventDefault();
      const { value } = newFocusTarget.dataset;

      ctx.onSelect(value);
    }
  };

  return (
    <Component
      role="tablist"
      className={cx(
        'cf-tab-navigation',
        { 'cf-tab-navigation-full-screen': fullWidth },
        className
      )}
      onKeyDown={handleKeyDown}
      ref={tabListRef}
      {...props}
    />
  );
};
TabList.propTypes = propTypes;
