import React, { PropTypes } from 'react';

class DropdownFilter extends React.PureComponent {
  constructor() {
    super();
    this.state = {
      rootElemWidth: null
    };
  }

  render() {
    const { children, baseCoordinates } = this.props;

    if (!baseCoordinates) {
      return null;
    }

    let style;

    if (this.state.rootElemWidth) {
      const topOffset = 5;
      const leftOffset = -2;

      style = {
        top: baseCoordinates.bottom + topOffset,
        left: baseCoordinates.right - this.state.rootElemWidth + leftOffset
      };
    } else {
      style = { left: '-99999px' };
    }

    return <div className="cf-dropdown-filter" style={style} ref={(rootElem) => {
      this.rootElem = rootElem;
    }}>
      <div className="cf-clear-filter-row">
        <button className="cf-text-button" onClick={this.props.clearFilters}
            disabled={!this.props.isClearEnabled}>
          <div className="cf-clear-filter-button-wrapper">
              Clear category filter
          </div>
        </button>
      </div>
      {children}
    </div>;
  }

  componentDidMount() {
    document.addEventListener('click', this.onGlobalClick, true);

    if (this.rootElem) {
      this.setState({
        rootElemWidth: this.rootElem.clientWidth
      });
    }
  }

  componentWillUnmount() {
    document.removeEventListener('click', this.onGlobalClick);
  }

  onGlobalClick = (event) => {
    if (!this.rootElem) {
      return;
    }

    const clickIsInsideThisComponent = this.rootElem.contains(event.target);

    if (!clickIsInsideThisComponent) {
      this.props.handleClose();
    }
  }
}

DropdownFilter.propTypes = {
  children: PropTypes.node,
  baseCoordinates: PropTypes.shape({
    bottom: PropTypes.number.isRequired,
    right: PropTypes.number.isRequired
  }),
  isClearEnabled: PropTypes.bool,
  clearFilters: PropTypes.func,
  handleClose: PropTypes.func
};

export default DropdownFilter;
