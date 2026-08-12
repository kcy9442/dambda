output "queue_url" { value = aws_sqs_queue.review_events.id }
output "queue_arn" { value = aws_sqs_queue.review_events.arn }
output "queue_name" { value = aws_sqs_queue.review_events.name }
output "dlq_name" { value = aws_sqs_queue.review_dlq.name }
output "state_machine_arn" { value = aws_sfn_state_machine.review_moderation.arn }
output "pipe_arn" { value = aws_pipes_pipe.review_moderation.arn }
