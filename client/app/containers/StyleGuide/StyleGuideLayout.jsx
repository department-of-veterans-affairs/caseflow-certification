import React from 'react';
import StyleGuideComponentTitle from '../../components/StyleGuideComponentTitle';
import Actions from '../../components/Actions';
import Button from '../../components/Button';
import InlineForm from '../../components/InlineForm';

export default class StyleGuideLayout extends React.Component {
   render () {
    return ( 
   <div>
      <StyleGuideComponentTitle
        title="Layout"
        id="layout"
        link="StyleGuideLayout.jsx"
        isSubsection={true}
      />
      <p>
        For most task-based pages, Primary and Secondary Actions sit under the App Canvas.
        The number of actions per page should be limited intentionally.
        These tasks should relate specifically to the user’s goal for the page they are on.
      </p>

      <p>
        The actions at the bottom of the page are arranged such as the primary
        task (the task that takes the user forward) is on the bottom right of the App Canvas.
        The label of this action usually hints at the title of the next page.
        Escape actions are placed to the left of the primary action.
        On the bottom left, of the App Canvas, there will be a back link,
        preferably with a description of where the user will go to
        or a link to the main page after a user has completed a task.
        These are actions that allow the user to move back a step
        or completely leave the task they’re working on.
      </p>
       <p>
        The consistent layout and arrangement of these actions reinforces the users mental model as the use Caseflow.
        You should avoid placing these actions in other parts of the page without good reason.
       </p>
      <Actions />
      <p>
         <div className="cf-app-segment" id="establish-claim-buttons">
          <div className="usa-width-one-half">
           <InlineForm>
            <span><Button
               name="Back to Preview"
               classNames={['cf-btn-link']} />
            </span>
          </InlineForm>
         </div>

         <div className ="cf-push-right">
           <Button
            name="Cancel"
           classNames={['cf-btn-link']}/>
          <Button
            name="Submit End Product"
          />
         </div>
        </div>
        </p>
    </div> 
      );
     }
  }
