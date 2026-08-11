output "queue_url" { value = aws_sqs_queue.review_events.id }
output "queue_arn" { value = aws_sqs_queue.review_events.arn }
output "queue_name" { value = aws_sqs_queue.review_events.name }
output "state_machine_arn" { value = aws_sfn_state_machine.review_moderation.arn }
output "event_bus_arn" { value = aws_cloudwatch_event_bus.review_events.arn }
output "event_bus_name" { value = aws_cloudwatch_event_bus.review_events.name }
