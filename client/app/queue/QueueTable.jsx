import React from 'react';
import PropTypes from 'prop-types';
import classnames from 'classnames';
import { css, hover } from 'glamor';
import _ from 'lodash';

import Tooltip from '../components/Tooltip';
import { DoubleArrow } from '../components/RenderFunctions';
import TableFilter from '../components/TableFilter';
import FilterSummary from '../components/FilterSummary';
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
  const iconHeaderStyle = css({ display: 'table-row' });
  const iconStyle = css({
    display: 'table-cell',
    paddingLeft: '1rem',
    paddingTop: '0.3rem',
    verticalAlign: 'middle'
  }, hover({ cursor: 'pointer' }));

  return <thead className={props.headerClassName}>
    <tr>
      {getColumns(props).map((column, columnNumber) => {
        let sortIcon;
        let filterIcon;

        if (column.getSortValue) {
          const topColor = props.sortColIdx === columnNumber && !props.sortAscending ?
            COLORS.PRIMARY :
            COLORS.GREY_LIGHT;
          const botColor = props.sortColIdx === columnNumber && props.sortAscending ?
            COLORS.PRIMARY :
            COLORS.GREY_LIGHT;

          sortIcon = <span {...iconStyle} onClick={() => props.setSortOrder(columnNumber)}>
            <DoubleArrow topColor={topColor} bottomColor={botColor} />
          </span>;
        }

        // Keeping the historical prop `getFilterValues` for backwards compatibility,
        // will remove this once all apps are using this new component.
        if (column.enableFilter || column.getFilterValues) {
          filterIcon = <TableFilter
            {...column}
            toggleDropdownFilterVisibility={(columnName) => props.toggleDropdownFilterVisibility(columnName)}
            isDropdownFilterOpen={props.isDropdownFilterOpen[column.columnName]}
            updateFilters={(newFilters) => props.updateFilteredByList(newFilters)}
            filteredByList={props.filteredByList} />;
        }

        const columnTitleContent = <span>{column.header || ''}</span>;
        const columnContent = <span {...iconHeaderStyle}>
          {columnTitleContent}
          {sortIcon}
          {filterIcon}
        </span>;

        return <th scope="col" key={columnNumber} className={cellClasses(column)}>
          { column.tooltip ?
            <Tooltip id={`tooltip-${columnNumber}`} text={column.tooltip}>{columnContent}</Tooltip> :
            <React.Fragment>{columnContent}</React.Fragment>
          }
        </th>;
      })}
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

    const { defaultSort } = this.props;
    const state = {
      sortAscending: true,
      sortColIdx: null,
      areDropdownFiltersOpen: {},
      filteredByList: {}
    };

    if (defaultSort) {
      Object.assign(state, defaultSort);
    }

    this.state = state;
  }

  defaultRowClassNames = () => ''

  sortRowObjects = () => {
    const { rowObjects } = this.props;
    const {
      sortColIdx,
      sortAscending
    } = this.state;

    if (sortColIdx === null) {
      return rowObjects;
    }

    const builtColumns = getColumns(this.props);

    return _.orderBy(rowObjects,
      (row) => builtColumns[sortColIdx].getSortValue(row),
      sortAscending ? 'asc' : 'desc'
    );
  }

  toggleDropdownFilterVisibility = (columnName) => {
    const originalValue = _.get(this.state, [
      'areDropdownFiltersOpen', columnName
    ], false);
    const newState = Object.assign({}, this.state);

    newState.areDropdownFiltersOpen[columnName] = !originalValue;
    this.setState({ newState });
  };

  updateFilteredByList = (newList) => {
    this.setState({ filteredByList: newList });
  };

  filterTableData = (data: Array<Object>) => {
    const { filteredByList } = this.state;
    const filteredData = _.clone(data);

    // Only filter the data if filters have been selected
    if (!_.isEmpty(filteredByList)) {
      for (const columnName in filteredByList) {
        // If there are no filters for this columnName,
        // continue to the next columnName
        if (_.isEmpty(filteredByList[columnName])) {
          continue; // eslint-disable-line no-continue
        }

        for (const key in data) {
          // If this data point does not match a filter in this columnName,
          // remove the data point from `filteredData`
          if (!filteredByList[columnName].includes(_.get(data[key], columnName))) {
            _.pull(filteredData, _.find(filteredData, ['uniqueId', data[key].uniqueId]));
          }
        }
      }
    }

    return filteredData;
  };

  render() {
    const {
      columns,
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
    let rowObjects = this.sortRowObjects();

    rowObjects = this.filterTableData(rowObjects);

    let keyGetter = getKeyForRow;

    if (!getKeyForRow) {
      keyGetter = _.identity;
      if (!slowReRendersAreOk) {
        console.warn('<Table> props: one of `getKeyForRow` or `slowReRendersAreOk` props must be passed. ' +
          'To learn more about keys, see https://facebook.github.io/react/docs/lists-and-keys.html#keys');
      }
    }

    return <div>
      <FilterSummary
        filteredByList={this.state.filteredByList}
        alternateColumnNames={this.props.alternateColumnNames}
        clearFilteredByList={(newList) => this.updateFilteredByList(newList)} />
      <table
        id={id}
        className={`usa-table-borderless ${this.props.className}`}
        summary={summary}
        {...styling} >

        { caption && <caption className="usa-sr-only">{ caption }</caption> }

        <HeaderRow
          columns={columns}
          headerClassName={headerClassName}
          setSortOrder={(colIdx, ascending = !this.state.sortAscending) => this.setState({
            sortColIdx: colIdx,
            sortAscending: ascending
          })}
          toggleDropdownFilterVisibility={this.toggleDropdownFilterVisibility}
          isDropdownFilterOpen={this.state.areDropdownFiltersOpen}
          updateFilteredByList={this.updateFilteredByList}
          filteredByList={this.state.filteredByList}
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
      </table>
    </div>;
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
  styling: PropTypes.object,
  defaultSort: PropTypes.shape({
    sortColIdx: PropTypes.number,
    sortAscending: PropTypes.bool
  }),
  userReadableColumnNames: PropTypes.object
};
