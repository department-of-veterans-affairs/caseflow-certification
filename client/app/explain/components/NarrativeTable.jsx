import React from 'react';
import useSelector from 'react-redux';
import QueueTable from '../../queue/QueueTable';
import EXPLAIN_CONFIG from '../../../constants/EXPLAIN';
import {
  timestampColumn,
  contextColumn,
  objectTypeColumn,
  eventTypeColumn,
  objectIdColumn,
  commentColumn,
  relevanttDataColumn,
  detailsColumn
} from './ColumnBuilder'
import Modal from '../../components/Modal'
import COPY from '../../../COPY';
import { css } from 'glamor';

class NarrativeTable extends React.PureComponent {
  constructor(props) {
    super(props);

    this.state = {
      modal: false,
      details: {}
    };
  }

  handleModalClose = () => {
    this.setState({ modal: false });
  };

  handleModalOpen = (details) => {
    this.setState({ modal: true, details: details });
  };

  filterValuesForColumn = (column) =>
    column && column.filterable && column.filter_options;

  createColumnObject = (column, narratives) => {
    const filterOptions = this.filterValuesForColumn(column);
    const functionForColumn = {
      [EXPLAIN_CONFIG.COLUMNS.TIMESTAMP.name]: timestampColumn(
        column
      ),
      [EXPLAIN_CONFIG.COLUMNS.OBJECT_TYPE.name]: objectTypeColumn(
        column,
        filterOptions
      ),
      [EXPLAIN_CONFIG.COLUMNS.EVENT_TYPE.name]: eventTypeColumn(
        column,
        filterOptions        
      ),
      [EXPLAIN_CONFIG.COLUMNS.COMMENT.name]: commentColumn(
        column
      ),
      [EXPLAIN_CONFIG.COLUMNS.RELEVANT_DATA.name]: relevanttDataColumn(
        column
      ),
      [EXPLAIN_CONFIG.COLUMNS.DETAILS.name]: detailsColumn(
        column,
        this.handleModalOpen
      )
    };
    return functionForColumn[column.name];
  }

  columnsFromConfig = (columns, narratives) => {
    let builtColumns = [];
    for (const [columnName, columnKeys] of Object.entries(columns)) {
      builtColumns.push(this.createColumnObject(columnKeys, narratives));
    }
    return builtColumns;
  }

  render = () => {
    const showModal = this.state.modal
    const narratives = this.props.eventData;
    const textAreaStyling = css({
      wideth: '100%',
      fontSize: '10pt'
    });

    return ( 
      <React.Fragment>
        <QueueTable 
          id="events_table"
          columns={this.columnsFromConfig(EXPLAIN_CONFIG.COLUMNS, narratives)}
          rowObjects={narratives}
          summary="test table" slowReRendersAreOk />
        {showModal && <React.Fragment>
          <Modal
            title="Details"
            buttons={[
              {
                classNames: ['usa-button', 'cf-btn-link'],
                name: COPY.MODAL_CLOSE_BUTTON,
                onClick: this.handleModalClose
              }
            ]}
            closeHandler={this.handleModalClose}
          >
            <textarea {...textAreaStyling}>{JSON.stringify(this.state.details)}</textarea>
          </Modal>
        </React.Fragment>}
      </React.Fragment>
    );
  };
}

export default NarrativeTable;
