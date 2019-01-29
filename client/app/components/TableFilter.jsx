import React from 'react';
import PropTypes from 'prop-types';
import _ from 'lodash';

import { css, hover } from 'glamor';
import FilterIcon from './FilterIcon';
import DropdownFilter from './DropdownFilter';
import FilterOption from './FilterOption';

/**
 * This component can be used to implement filtering for a table column.
 * The required props are:
 * - @column {array[string]} array of objects that define the properties
 *   of the column. Possible attributes for each column include:
 *   - @enableFilter {boolean} whether filtering is turned on for each column
 *   - @tableData {object} the entire data set for the table (required to calculate
 *     the options each column can be filtered on)
 *   - @columnName {string} the name of the column in the table data
 *   - @toggleDropdownFilterVisibility {function} changes the status of the filter
 *     dropdown's visibility, and dispatches an action to change a new value in the
 *     store to capture this information
 *   - @filteredByList {object} the list of filters that have been selected;
 *     this data comes from the store, and is an object where each key is a column name,
 *     which then points to an array of the specific options that column is filtered by
 *   - @updateFilters {function} updates the filteredByList
 *   - @isDropdownFilterOpen {object} a property from the store that is updated by
 *     toggleDropdownFilterVisibility, and should receive the specific column name
 *   - @anyFiltersAreSet {boolean} determines whether the "Clear All Filters" option
 *     in the dropdown is enabled
 *   - @customFilterLabels {object} key-value pairs translating the data values to
 *     user readable text
 *   - @label {string} used for the aria-label on the icon,
 *   - @valueName {string} if valueFunction is not defined, cell value will use
 *     valueName to pull that attribute from the rowObject.
 */

class TableFilter extends React.PureComponent {
  filterDropdownOptions = (tableDataByRow, columnName) => {
    let countByColumnName = _.countBy(tableDataByRow, columnName);
    let uniqueOptions = [];
    const filtersForColumn = _.get(this.props.column.filteredByList, columnName);
    const { customFilterLabels } = this.props.column;

    for (let key in countByColumnName) {
      if (key && key !== 'null' && key !== 'undefined') {
        if (customFilterLabels && customFilterLabels[key]) {
          uniqueOptions.push({
            value: key,
            displayText: `${customFilterLabels[key]} (${countByColumnName[key]})`,
            checked: filtersForColumn ? filtersForColumn.includes(key) : false
          });
        } else {
          uniqueOptions.push({
            value: key,
            displayText: `${_.capitalize(key)} (${countByColumnName[key]})`,
            checked: filtersForColumn ? filtersForColumn.includes(key) : false
          });
        }
      } else {
        uniqueOptions.push({
          value: 'null',
          displayText: `<<blank>> (${countByColumnName[key]})`
        });
      }
    }

    return _.sortBy(uniqueOptions, 'displayText');
  }

  updateSelectedFilter = (value, columnName) => {
    const oldList = this.props.column.filteredByList;
    const filtersForColumn = _.get(oldList, String(columnName));
    let newList = {};
    let newFilters = [];

    if (filtersForColumn) {
      if (filtersForColumn.includes(value)) {
        newFilters = _.pull(filtersForColumn, value);
      } else {
        newFilters = filtersForColumn.concat([value]);
      }
    } else {
      newFilters = newFilters.concat([value]);
    }

    newList[columnName] = newFilters;
    this.props.column.updateFilters(newList);

    // For some reason when filters are removed a render doesn't automatically happen
    this.forceUpdate();
  }

  clearFilteredByList = (columnName) => {
    const oldList = this.props.column.filteredByList;
    let newList = _.set(oldList, columnName, []);

    this.props.column.updateFilters(newList);
    this.props.column.toggleDropdownFilterVisibility();
  }

  render() {
    const {
      column
    } = this.props;

    const iconStyle = css({
      display: 'table-cell',
      paddingLeft: '1rem',
      paddingTop: '0.3rem',
      verticalAlign: 'middle'
    }, hover({ cursor: 'pointer' }));

    const filterOptions = column.tableData && column.columnName ?
      this.filterDropdownOptions(column.tableData, column.columnName) :
      // Keeping the historical prop `getFilterValues` for backwards compatibility,
      // will remove this once all apps are using this new component.
      column.getFilterValues;

    return (
      <span {...iconStyle}>
        <FilterIcon
          label={column.label}
          idPrefix={column.valueName}
          getRef={column.getFilterIconRef}
          selected={column.isDropdownFilterOpen || column.filteredByList[column.columnName]}
          handleActivate={column.toggleDropdownFilterVisibility} />

        {column.isDropdownFilterOpen &&
          <DropdownFilter
            clearFilters={() => this.clearFilteredByList(column.columnName)}
            name={column.valueName}
            isClearEnabled={column.anyFiltersAreSet}
            handleClose={column.toggleDropdownFilterVisibility}
            addClearFiltersRow>
            <FilterOption
              options={filterOptions}
              setSelectedValue={(value) => this.updateSelectedFilter(value, column.columnName)} />
          </DropdownFilter>
        }
      </span>
    );
  }
}

TableFilter.propTypes = {
  column: PropTypes.oneOfType([
    PropTypes.arrayOf(PropTypes.object),
    PropTypes.func]).isRequired
};

export default TableFilter;
