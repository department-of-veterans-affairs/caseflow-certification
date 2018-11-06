import { css } from 'glamor';
import React from 'react';

import StringUtil from '../util/StringUtil';
import { COLORS } from '../constants/AppConstants';

const sectionNavigationContainerStyling = css({
  float: 'left',
  paddingRight: '3rem',
  position: 'sticky',
  top: '3rem',
  width: '20%',
  '@media (max-width: 920px)': {
    top: '1rem',
    paddingRight: 0,
    // borderRadius: '5px',
    // justifyContent: 'space-between',
    // width: '100%',
  }
});

const sectionNavStyling = css({
  '@media (max-width: 920px)': {
    '&': {
      display: 'flex',
      flexFlow: 'row wrap'
    },
    '& > *': {
      flex: '1 auto'
    }
  }
});

const sectionNavigationListStyling = css({
  '& > li': {
    backgroundColor: COLORS.GREY_BACKGROUND,
    color: COLORS.PRIMARY,
    borderWidth: 0
  },
  '& > li:hover': {
    backgroundColor: COLORS.GREY_DARK,
    color: COLORS.WHITE
  },
  '& > li > a': { color: COLORS.PRIMARY },
  '& > li:hover > a': {
    background: 'none',
    color: COLORS.WHITE
  },
  '& > li > a:after': {
    content: '〉',
    float: 'right'
  },
  '@media (max-width: 920px)': {
    display: 'flex',
    flexFlow: 'row',
    borderBottom: 'none',
    borderTop: 'none',
    width: '100%',
    marginBottom: '30px',
    '& > li': {
      padding: '8.5px 10px',
      fontSize: '13px',
      flexGrow: 1,
      '&:first-child': {
        borderRadius: '5px 0 0 5px'
      },
      '&:last-child': {
        borderRadius: '0 5px 5px 0'
      },
      '& a': {
        padding: 0
      },
      '& > a:after': {
        content: 'none'
      }
    }
  }
});

const sectionBodyStyling = css({
  float: 'left',
  width: '80%',
  '@media (max-width: 920px)': {
    flex: '1 100%'
  }
});

const getIdForElement = (elem) => `${StringUtil.parameterize(elem.props.title)}-section`;

export default class StickyNavContentArea extends React.PureComponent {
  render = () => {
    // Ignore undefined child elements.
    const childElements = this.props.children.filter((child) => typeof child === 'object');

    return <div {...sectionNavStyling}>
      <aside {...sectionNavigationContainerStyling}>
        <ul className="usa-sidenav-list" {...sectionNavigationListStyling}>
          {childElements.map((child, i) =>
            <li key={i}><a href={`#${getIdForElement(child)}`}>{child.props.title}</a></li>)}
        </ul>
      </aside>

      <div {...sectionBodyStyling}>
        {childElements.map((child, i) => <ContentSection key={i} element={child} />)}
      </div>
    </div>;
  };
}

const sectionSegmentStyling = css({
  border: `1px solid ${COLORS.GREY_LIGHT}`,
  borderTop: '0px',
  marginBottom: '3rem',
  padding: '1rem 2rem'
});

const sectionHeadingStyling = css({
  backgroundColor: COLORS.GREY_BACKGROUND,
  border: `1px solid ${COLORS.GREY_LIGHT}`,
  borderBottom: 0,
  borderRadius: '0.5rem 0.5rem 0 0',
  margin: 0,
  padding: '1rem 2rem'
});

const anchorJumpLinkStyling = css({
  color: COLORS.GREY_DARK,
  paddingTop: '60px',
  textDecoration: 'none',
  pointerEvents: 'none',
  cursor: 'default'
});

const ContentSection = ({ element }) => <React.Fragment>
  <h2 {...sectionHeadingStyling}>
    <a id={`${getIdForElement(element)}`} {...anchorJumpLinkStyling}>{element.props.title}</a>
  </h2>
  <div {...sectionSegmentStyling}>{element}</div>
</React.Fragment>;

