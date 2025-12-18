# Example EMF custom metrics publisher
import json, time, sys
def emit_latency(latency_ms: int):
    print(json.dumps({
        "_aws": {
            "Timestamp": int(time.time()*1000),
            "CloudWatchMetrics": [{
                "Namespace": "DemoApp",
                "Dimensions": [["Service"]],
                "Metrics": [{"Name":"Latency","Unit":"Milliseconds"}]
            }]
        },
        "Service": "api",
        "Latency": latency_ms
    }))
if __name__ == "__main__":
    emit_latency(123)
