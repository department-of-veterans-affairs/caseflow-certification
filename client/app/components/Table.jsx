import React from 'react';
import PropTypes from 'prop-types';
import classnames from 'classnames';
import _ from 'lodash';
import ReactTooltip from 'react-tooltip';

import { ChevronUp, ChevronDown } from './RenderFunctions';
import { css, hover } from 'glamor';
import { COLORS } from '../constants/AppConstants';

/**
 * This component can be used to easily build tables.
 * The required props are:
 * - @columns {array[string]} array of objects that define the properties
 *   of the columns. Possible attributes for each column include:
 *   - @header {string|component} header cell value for the column
 *   - @align {sting} alignment of the column ("left", "right", or "center")
 *   - @valueFunction {function(rowObject)} function that takes `rowObject` as
 *     an argument and returns the value of the cell for that column.
 *   - @valueName {string} if valueFunction is not defined, cell value will use
 *     valueName to pull that attribute from the rowObject.
 *   - @footer {string} footer cell value for the column
 * - @rowObjects {array[object]} array of objects used to build the <tr/> rows
 * - @summary {string} table summary
 *
 * see StyleGuideTables.jsx for usage example.
 */
const helperClasses = {
  center: 'cf-txt-c',
  left: 'cf-txt-l',
  right: 'cf-txt-r'
};

const cellClasses = ({ align, cellClass }) => classnames([helperClasses[align], cellClass]);

const getColumns = (props) => {
  return _.isFunction(props.columns) ?
    props.columns(props.rowObject) : props.columns;
};

const HeaderRow = (props) => {
  const sortableHeaderStyle = css(
    { color: COLORS.PRIMARY },
    hover({ cursor: 'pointer' })
  );

  return <thead className={props.headerClassName}>
    <tr>
      {getColumns(props).map((column, columnNumber) =>
        <th scope="col" key={columnNumber} className={cellClasses(column)}>
          {column.tooltip && <ReactTooltip id={`${columnNumber}-tooltip`} effect="solid" multiline>
            {column.tooltip}
          </ReactTooltip>}
          {column.sortable ?
            <span {...sortableHeaderStyle}
              data-tip data-for={`${columnNumber}-tooltip`}
              onClick={() => props.setSortOrder(columnNumber)}>
              {column.header || ''} {props.sortColIdx === columnNumber && (
                props.sortDir > 0 ? <ChevronDown /> : <ChevronUp />
              )}
            </span> :
            <span data-tip data-for={`${columnNumber}-tooltip`}>{column.header || ''}</span>
          }
        </th>
      )}
    </tr>
  </thead>;
};

const getCellValue = (rowObject, rowId, column) => {
  if (column.valueFunction) {
    return column.valueFunction(rowObject, rowId);
  }
  if (column.valueName) {
    return rowObject[column.valueName];
  }

  return '';
};

const getCellSpan = (rowObject, column) => {
  if (column.span) {
    return column.span(rowObject);
  }

  return 1;
};

// todo: make these functional components?
class Row extends React.PureComponent {
  render() {
    const props = this.props;
    const rowId = props.footer ? 'footer' : props.rowId;
    const rowClassnameCondition = classnames(!props.footer && props.rowClassNames(props.rowObject));

    return <tr id={`table-row-${rowId}`} className={rowClassnameCondition}>
      {getColumns(props).
        filter((column) => getCellSpan(props.rowObject, column) > 0).
        map((column, columnNumber) =>
          <td
            key={columnNumber}
            className={cellClasses(column)}
            colSpan={getCellSpan(props.rowObject, column)}>
            {props.footer ?
              column.footer :
              getCellValue(props.rowObject, props.rowId, column)}
          </td>
        )}
    </tr>;
  }
}

class BodyRows extends React.PureComponent {
  render() {
    const { rowObjects, bodyClassName, columns, rowClassNames, tbodyRef, id, getKeyForRow, bodyStyling } = this.props;

    return <tbody className={bodyClassName} ref={tbodyRef} id={id} {...bodyStyling}>
      {rowObjects.map((object, rowNumber) => {
        const key = getKeyForRow(rowNumber, object);

        return <Row
          rowObject={object}
          columns={columns}
          rowClassNames={rowClassNames}
          key={key}
          rowId={key} />;
      }
      )}
    </tbody>;
  }
}

class FooterRow extends React.PureComponent {
  render() {
    const props = this.props;
    const hasFooters = _.some(props.columns, 'footer');

    return <tfoot>
      {hasFooters && <Row columns={props.columns} footer />}
    </tfoot>;
  }
}

export default class Table extends React.PureComponent {
  constructor(props) {
    super(props);

    this.state = {
      sortDir: 1,
      sortColIdx: null
    };
  }

  defaultRowClassNames = () => ''

  render() {
    let {
      columns,
      rowObjects,
      summary,
      headerClassName = '',
      bodyClassName = '',
      rowClassNames = this.defaultRowClassNames,
      getKeyForRow,
      slowReRendersAreOk,
      tbodyId,
      tbodyRef,
      caption,
      id,
      styling,
      bodyStyling
    } = this.props;
    const {
      sortColIdx,
      sortDir
    } = this.state;

    let keyGetter = getKeyForRow;

    if (!getKeyForRow) {
      keyGetter = _.identity;
      if (!slowReRendersAreOk) {
        console.warn('<Table> props: one of `getKeyForRow` or `slowReRendersAreOk` props must be passed. ' +
          'To learn more about keys, see https://facebook.github.io/react/docs/lists-and-keys.html#keys');
      }
    }

    if (sortColIdx !== null) {
      const isNumber = (val) => !isNaN(parseFloat(val)) && isFinite(val);

      rowObjects.sort((first, second) => {
        const builtColumns = getColumns(this.props);

        const firstVal = builtColumns[sortColIdx].getSortValue(first).toString();
        const secondVal = builtColumns[sortColIdx].getSortValue(second).toString();

        // eslint-disable-next-line no-undefined
        return sortDir * firstVal.localeCompare(secondVal, undefined, { numeric: isNumber(firstVal) });
      });
    }

    return <table
      id={id}
      className={`usa-table-borderless cf-table-borderless ${this.props.className}`}
      summary={summary}
      {...styling} >

      { caption && <caption className="usa-sr-only">{ caption }</caption> }

      <HeaderRow
        columns={columns}
        headerClassName={headerClassName}
        setSortOrder={(colIdx, dir = this.state.sortDir * -1) => this.setState({
          sortColIdx: colIdx,
          sortDir: dir
        })}
        {...this.state} />
      <BodyRows
        id={tbodyId}
        tbodyRef={tbodyRef}
        columns={columns}
        getKeyForRow={keyGetter}
        rowObjects={rowObjects}
        bodyClassName={bodyClassName}
        rowClassNames={rowClassNames}
        bodyStyling={bodyStyling}
        {...this.state} />
      <FooterRow columns={columns} />
    </table>;
  }
}

Table.propTypes = {
  tbodyId: PropTypes.string,
  tbodyRef: PropTypes.func,
  columns: PropTypes.oneOfType([
    PropTypes.arrayOf(PropTypes.object),
    PropTypes.func]).isRequired,
  rowObjects: PropTypes.arrayOf(PropTypes.object).isRequired,
  rowClassNames: PropTypes.func,
  keyGetter: PropTypes.func,
  slowReRendersAreOk: PropTypes.bool,
  summary: PropTypes.string,
  headerClassName: PropTypes.string,
  className: PropTypes.string,
  caption: PropTypes.string,
  id: PropTypes.string,
  styling: PropTypes.object
};
