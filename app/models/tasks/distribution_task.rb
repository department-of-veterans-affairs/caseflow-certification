class DistributionTask < GenericTask
	# Prevent this task from being marked complete 
	# when a child task (e.g. evidence submission)
	# is marked complete.
	def update_status_if_children_tasks_are_complete
		if children.any? && children.all? { |t| t.status == Constants.TASK_STATUSES.completed }
			update!(status: :assigned)
		end
	end
end
