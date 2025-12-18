# CloudWatch Logs Insights Query Examples

## Error Analysis

### Count errors by type
```
fields @timestamp, @message
| filter @message like /ERROR/
| parse @message "ERROR * - *" as errorType, errorMessage
| stats count(*) as errorCount by errorType
| sort errorCount desc
| limit 20
```

### Error rate over time
```
fields @timestamp
| filter @message like /ERROR/
| stats count(*) as errors by bin(5m)
| sort @timestamp desc
```

### Top error messages
```
fields @timestamp, @message
| filter @message like /ERROR/
| stats count(*) as count by @message
| sort count desc
| limit 10
```

## Latency Analysis

### P50, P90, P99 latency
```
fields @timestamp, @message
| parse @message "latency=*ms" as latency
| stats avg(latency) as avg_latency,
        pct(latency, 50) as p50,
        pct(latency, 90) as p90,
        pct(latency, 99) as p99
  by bin(5m)
| sort @timestamp desc
```

### Slow requests (>1s)
```
fields @timestamp, @message
| parse @message "latency=*ms" as latency
| filter latency > 1000
| sort latency desc
| limit 50
```

## Request Patterns

### Requests per minute
```
fields @timestamp
| stats count(*) as requests by bin(1m)
| sort @timestamp desc
```

### Requests by endpoint
```
fields @timestamp, @message
| parse @message 'path="*"' as path
| stats count(*) as requests by path
| sort requests desc
| limit 20
```

### Status code distribution
```
fields @timestamp, @message
| parse @message 'status=*' as status
| stats count(*) as count by status
| sort count desc
```

## Container/ECS Specific

### Container restarts
```
fields @timestamp, @message
| filter @message like /Starting/ or @message like /Stopping/
| sort @timestamp desc
| limit 50
```

### Memory usage patterns
```
fields @timestamp, @message
| parse @message "memory_used=*MB" as memory
| stats avg(memory) as avg_memory, max(memory) as max_memory by bin(5m)
| sort @timestamp desc
```

## Troubleshooting

### Find specific request by ID
```
fields @timestamp, @message
| filter @message like /REQUEST_ID_HERE/
| sort @timestamp asc
```

### Exceptions with stack traces
```
fields @timestamp, @message
| filter @message like /Exception/ or @message like /Traceback/
| limit 20
```

### Cold starts (Lambda)
```
fields @timestamp, @message, @duration
| filter @type = "REPORT"
| filter @message like /Init Duration/
| parse @message "Init Duration: * ms" as initDuration
| stats count(*) as coldStarts, avg(initDuration) as avgInitDuration by bin(1h)
```
