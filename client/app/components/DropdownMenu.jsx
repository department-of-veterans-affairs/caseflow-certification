import React from 'react';
import PropTypes from 'prop-types';
import Link from './Link';
import Button from './Button';

// Lots of this class are taken from
// https://stackoverflow.com/questions/32553158/detect-click-outside-react-component

export default class DropdownMenu extends React.Component {
  constructor(props) {
    super(props);

    this.wrapperRef = null;
    this.state = {
      menu: false
    };
  }

  componentDidMount = () => document.addEventListener('mousedown', this.onClickOutside);

  componentWillUnmount = () => document.removeEventListener('mousedown', this.onClickOutside);

  setWrapperRef = (node) => this.wrapperRef = node

  onClickOutside = (event) => {
    if (this.wrapperRef && !this.wrapperRef.contains(event.target)) {
      window.analyticsEvent('Navbar', 'menu', 'close', 'blur');

      this.setState({
        menu: false
      });
    }
  }

  onClick = (title) => () => {
    window.analyticsEvent('Navbar', title.toLowerCase());
  }

  onMenuClick = () => {
    window.analyticsEvent('Navbar', 'menu', this.state.menu ? 'close' : 'open');

    this.setState((prevState) => ({
      menu: !prevState.menu
    }));
  };

  render() {
    let {
      analyticsTitle,
      label,
      options
    } = this.props;

    let dropdownMenuList = () => {
      return <ul className="cf-dropdown-menu active"
        aria-labelledby="menu-trigger">
        {options.map((option, index) =>
          <li key={index}>
            {options.length - 1 === index && <div className="dropdown-border"></div>}
            <Link
              href={option.link}
              target={option.target}
              onClick={this.onClick(option.title)}>{option.title}</Link>
          </li>)}
      </ul>;
    };

    return <div ref={this.setWrapperRef} className="cf-dropdown">
      <a href="#dropdown-menu"
        className="cf-dropdown-trigger"
        onClick={this.onMenuClick}>
        {label}
      </a>
      {this.state.menu && dropdownMenuList() }
    </div>;
  }
}

DropdownMenu.propTypes = {
  options: PropTypes.arrayOf(PropTypes.shape({
    title: PropTypes.string.isRequired,
    link: PropTypes.string.isRequired,
    target: PropTypes.string
  })),
  label: PropTypes.string.isRequired
};
