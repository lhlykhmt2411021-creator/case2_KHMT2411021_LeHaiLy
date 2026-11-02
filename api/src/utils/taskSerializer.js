function toUserRef(user) {
  if (!user) {
    return null;
  }
  if (user._id) {
    return { id: user._id.toString(), fullName: user.fullName, email: user.email };
  }
  return { id: user.toString() };
}

function toTaskSummary(task) {
  return {
    id: task._id.toString(),
    title: task.title,
    description: task.description,
    status: task.status,
    priority: task.priority,
    startDate: task.startDate,
    dueDate: task.dueDate,
    createdAt: task.createdAt,
    updatedAt: task.updatedAt,
    createdBy: toUserRef(task.createdBy),
    primaryAssignee: toUserRef(task.primaryAssigneeId),
    assigneeCount: task.assigneeIds ? task.assigneeIds.length : 0,
  };
}

function toShare(share) {
  return {
    id: share._id.toString(),
    permission: share.permission,
    user: toUserRef(share.userId),
    sharedBy: toUserRef(share.sharedBy),
    createdAt: share.createdAt,
  };
}

function toTaskDetail(task, role, shares) {
  return {
    ...toTaskSummary(task),
    role,
    assignees: (task.assigneeIds || []).map(toUserRef),
    shares: shares.map(toShare),
  };
}

function toActivity(activity) {
  return {
    id: activity._id.toString(),
    action: activity.action,
    details: activity.details,
    user: toUserRef(activity.userId),
    createdAt: activity.createdAt,
  };
}

module.exports = { toActivity, toShare, toTaskDetail, toTaskSummary, toUserRef };
