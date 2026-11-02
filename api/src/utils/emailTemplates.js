function formatDate(value) {
  if (!value) {
    return 'Chưa đặt';
  }
  const date = value instanceof Date ? value : new Date(value);
  if (Number.isNaN(date.getTime())) {
    return 'Chưa đặt';
  }
  const day = String(date.getDate()).padStart(2, '0');
  const month = String(date.getMonth() + 1).padStart(2, '0');
  return `${day}/${month}/${date.getFullYear()}`;
}

const STATUS_LABELS = {
  todo: 'Chưa thực hiện',
  in_progress: 'Đang thực hiện',
  completed: 'Đã hoàn thành',
};

const PRIORITY_LABELS = {
  low: 'Thấp',
  medium: 'Trung bình',
  high: 'Cao',
};

function taskSummaryLines(task) {
  return [
    `Công việc: ${task.title}`,
    `Trạng thái: ${STATUS_LABELS[task.status] || task.status}`,
    `Mức ưu tiên: ${PRIORITY_LABELS[task.priority] || task.priority}`,
    `Hạn hoàn thành: ${formatDate(task.dueDate)}`,
  ];
}

function buildEmail(eventType, { task, recipient, actorName }) {
  const lines = taskSummaryLines(task);
  let subject;
  let intro;

  switch (eventType) {
    case 'assigned':
      subject = `[Task Manager] Bạn được giao công việc: ${task.title}`;
      intro = `${actorName} đã giao cho bạn công việc "${task.title}".`;
      break;
    case 'shared':
      subject = `[Task Manager] Công việc được chia sẻ với bạn: ${task.title}`;
      intro = `${actorName} đã chia sẻ công việc "${task.title}" với bạn.`;
      break;
    case 'due_date_changed':
      subject = `[Task Manager] Hạn hoàn thành thay đổi: ${task.title}`;
      intro = `${actorName} đã đổi hạn hoàn thành công việc "${task.title}".`;
      break;
    case 'completed':
      subject = `[Task Manager] Công việc đã hoàn thành: ${task.title}`;
      intro = `Công việc "${task.title}" đã được ${actorName} đánh dấu hoàn thành.`;
      break;
    case 'reminder':
      subject = `[Task Manager] Nhắc hạn hoàn thành: ${task.title}`;
      intro = `Công việc "${task.title}" sắp đến hạn hoàn thành.`;
      break;
    default:
      subject = `[Task Manager] Cập nhật công việc: ${task.title}`;
      intro = `${actorName} vừa cập nhật công việc "${task.title}".`;
      break;
  }

  const text = [
    `Xin chào ${recipient.fullName || recipient.email},`,
    '',
    intro,
    '',
    ...lines,
    '',
    'Vui lòng mở ứng dụng Task Manager để xem chi tiết.',
  ].join('\n');

  const html = `<p>Xin chào <strong>${recipient.fullName || recipient.email}</strong>,</p>
<p>${intro}</p>
<ul>${lines.map((line) => `<li>${line}</li>`).join('')}</ul>
<p>Vui lòng mở ứng dụng Task Manager để xem chi tiết.</p>`;

  return { subject, text, html };
}

module.exports = { buildEmail, formatDate };
